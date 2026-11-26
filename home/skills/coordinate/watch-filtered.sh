#!/usr/bin/env bash
# usage: watch-filtered.sh <session-id> <block-id> <transcript>
# watch.lua for a worker that ends a turn at every wait on a background run.
# Prints a done: line only when the worker's last text looks like a result or a question.
set -u
rex do -s "$1" --for 30m ~/.claude/skills/coordinate/watch.lua block="$2" | while IFS= read -r line; do
  if [[ $line != done:* ]]; then
    echo "$line"
    continue
  fi
  sleep 3 # the transcript lags the status event
  last=$(jq -rs '[.[] | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text] | last // ""' "$3" 2>/dev/null)
  if (( ${#last} > 800 )) || rg -qi '\?|pull/|PR #|opened|commit|decision|recommend|denied|blocked|report|pass|fail|follow-up|skipped' <<<"$last"; then
    echo "done: $(tr '\n' ' ' <<<"$last" | tail -c 300)"
  fi
done
