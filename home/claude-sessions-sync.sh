# Copy this machine's Claude Code transcripts into ~/claude-sessions/<host>/, which Syncthing
# shares with the other machines. rsync never deletes here, so the archive outlives Claude's
# own cleanup. Each host writes only its own subfolder, so Syncthing never sees conflicts.
host=$(hostname -s | tr '[:upper:]' '[:lower:]')
dst="$HOME/claude-sessions/$host"
mkdir -p "$dst"

for src in projects plans history.jsonl; do
  if [ -e "$HOME/.claude/$src" ]; then
    rsync -a "$HOME/.claude/$src" "$dst/"
  fi
done
