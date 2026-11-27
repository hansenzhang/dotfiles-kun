# Self-hosted GitHub Actions runners, one repo-level runner per container, one job at a time each.
# Jobs run in an Ubuntu runner image because the workflows' setup actions and apt installs expect Ubuntu.
# A host imports `import ../github-runners.nix { host = "oci"; names = [ ... ]; ... }`.
# The runner adds its default labels (self-hosted, Linux, ARM64 or X64) to `labels`.
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
{ host, names, labels, memory, cpus ? null }:

{ lib, ... }:
let
  stateDir = name: "/var/lib/github-runner/${name}";

  runner = name: {
    image = "myoung34/github-runner:2.338.2-ubuntu-noble";
    environmentFiles = [ "${stateDir name}/env" ];
    environment = {
      RUNNER_NAME = "${host}-${name}";
      RANDOM_RUNNER_SUFFIX = "false";
      RUNNER_WORKDIR = "${stateDir name}/work";
      TMPDIR = "${stateDir name}/tmp";
      CONFIGURED_ACTIONS_RUNNER_FILES_DIR = "${stateDir name}/config";
      # The saved registration is reused, so a stop must not deregister it.
      DISABLE_AUTOMATIC_DEREGISTRATION = "true";
      LABELS = labels;
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
    # Containers that jobs start through the socket are outside these caps. Host networking, because
    # jobs start servers on 127.0.0.1 that their `docker run --network host` containers connect to.
    extraOptions = [ "--memory=${memory}" "--memory-swap=${memory}" "--network=host" ]
      ++ lib.optional (cpus != null) "--cpus=${toString cpus}";
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
}
