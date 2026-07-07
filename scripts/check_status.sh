#!/usr/bin/env bash
set -euo pipefail

URL="https://www.electromaps.com/mapi/v2/locations/62891"
DATA_DIR="data"
HISTORY_FILE="$DATA_DIR/history.csv"
STATE_FILE="$DATA_DIR/last_state.json"

mkdir -p "$DATA_DIR"

if [ ! -f "$HISTORY_FILE" ]; then
  echo "timestamp_utc,connector,status" > "$HISTORY_FILE"
fi

if [ ! -f "$STATE_FILE" ]; then
  echo '{}' > "$STATE_FILE"
fi

RESPONSE=$(curl -sS --fail -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" "$URL")

echo "$RESPONSE" | jq -c '.connectors[]' | while read -r conn; do
  visualRef=$(echo "$conn" | jq -r '.visualRef')
  status=$(echo "$conn" | jq -r '.status')
  updated=$(echo "$conn" | jq -r '.status_updated_at')

  last_updated=$(jq -r --arg k "$visualRef" '.[$k].updated // ""' "$STATE_FILE")

  if [ "$updated" != "$last_updated" ]; then
    echo "$updated,$visualRef,$status" >> "$HISTORY_FILE"

    tmp=$(mktemp)
    jq --arg k "$visualRef" --arg updated "$updated" --arg status "$status" \
      '.[$k] = {updated: $updated, status: $status}' "$STATE_FILE" > "$tmp"
    mv "$tmp" "$STATE_FILE"
  fi
done
