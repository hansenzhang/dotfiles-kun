{ config, lib, pkgs, ... }:

# Self-hosted GitHub Actions runners, one repo-level runner per container, one job at a time each.
# Jobs run in an Ubuntu runner image because the workflows' setup actions and apt installs expect Ubuntu.
#
# Each runner keeps its state in /var/lib/github-runner/<name>/ (root only):
#   env     REPO_URL=https://github.com/<owner>/<repo>, plus RUNNER_TOKEN for the first start only
#   config  the registration (.runner, .credentials) the image saves and reuses on later starts
#   work    job checkouts, mounted at the same path inside, so `docker run -v "$PWD:..."` resolves on the host
#   tmp     TMPDIR, mounted the same way for jobs that bind-mount temporary directories
#
# Register a runner once:
#   gh api -X POST repos/<owner>/<repo>/actions/runners/registration-token --jq .token
#   put REPO_URL and RUNNER_TOKEN=<token> in the env file, then `systemctl restart docker-<name>`
#   once it shows online, delete the RUNNER_TOKEN line (the token expires in an hour anyway).
let
  names = [ "runner-1" "runner-2" ];
  stateDir = name: "/var/lib/github-runner/${name}";

  runner = name: {
    image = "myoung34/github-runner:2.338.2-ubuntu-noble";
    environmentFiles = [ "${stateDir name}/env" ];
    environment = {
      RUNNER_NAME = "oci-${name}";
      RANDOM_RUNNER_SUFFIX = "false";
      RUNNER_WORKDIR = "${stateDir name}/work";
      TMPDIR = "${stateDir name}/tmp";
      CONFIGURED_ACTIONS_RUNNER_FILES_DIR = "${stateDir name}/config";
      # The saved registration is reused, so a stop must not deregister it.
      DISABLE_AUTOMATIC_DEREGISTRATION = "true";
      LABELS = "oci";
      # Hosted runners set it; setup actions such as erlef/setup-beam pick their builds by it.
      ImageOS = "ubuntu24";
    };
    volumes = [
      "${stateDir name}/config:${stateDir name}/config"
      "${stateDir name}/work:${stateDir name}/work"
      "${stateDir name}/tmp:${stateDir name}/tmp"
      # Jobs' docker commands use the host's Docker.
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    # Containers that jobs start through the socket are outside this cap. Host networking, because
    # jobs start servers on 127.0.0.1 that their `docker run --network host` containers connect to.
    extraOptions = [ "--memory=4g" "--memory-swap=4g" "--network=host" ];
  };
in
{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = lib.genAttrs names runner;

  systemd.tmpfiles.rules = [ "d /var/lib/github-runner 0700 root root -" ]
    ++ lib.concatMap (name: [
      "d ${stateDir name} 0700 root root -"
      "d ${stateDir name}/config 0700 root root -"
      "d ${stateDir name}/work 0700 root root -"
      "d ${stateDir name}/tmp 0700 root root 3d"
    ]) names;

  # Cloudflare container images are linux/amd64. This registers a static qemu with the fix-binary flag,
  # so the kernel preloads it and it also runs inside Docker's build containers. Not
  # boot.binfmt.preferStaticEmulators: the binary cache lacks its static qemu, so oci would compile it from source.
  systemd.services.binfmt-amd64 = {
    description = "Register qemu for linux/amd64 binaries";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.virtualisation.docker.package pkgs.util-linux ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # The kernel drops registrations when the last binfmt_misc mount goes away, so the host holds one.
    script = ''
      mountpoint -q /proc/sys/fs/binfmt_misc || mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
      docker run --rm --privileged tonistiigi/binfmt:qemu-v10.2.3-68 --install amd64
    '';
  };

  # Jobs leave images and build cache behind. Not virtualisation.docker.autoPrune: its `docker system
  # prune` also deletes stopped containers, which other projects on this host keep.
  systemd.services.docker-image-prune = {
    description = "Prune unused Docker images and build cache";
    # After the runners, so a prune at boot does not delete their image before they start.
    after = [ "docker.service" ] ++ map (name: "docker-${name}.service") names;
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    path = [ config.virtualisation.docker.package ];
    script = ''
      docker image prune --all --force --filter until=72h
      docker builder prune --all --force --filter until=72h
    '';
  };
  systemd.timers.docker-image-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
