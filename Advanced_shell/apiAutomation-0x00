#!/usr/bin/env bash
# apiAutomation-0x00.sh
# Fetch Pokémon data from the PokeAPI and save it to a file.
# Usage: ./apiAutomation-0x00.sh [pokemon_name] 

set -euo pipefail

POKE_NAME="${1:-pikachu}"
API_URL="https://pokeapi.co/api/v2/pokemon/${POKE_NAME}"
OUT_FILE="data.json"
ERR_FILE="errors.txt"
UA="pokefetch/1.0"
RETRIES=3

timestamp() { date -Iseconds; }  # e.g., 2025-08-08T23:05:45+03:00
log_error() { echo "[$(timestamp)] $*" >> "$ERR_FILE"; }

attempt=1
while :; do
  TMP_FILE="$(mktemp)"
  # curl writes body to TMP_FILE, and we capture the HTTP status code via -w
  # -sS: silent but still show errors, -L: follow redirects, timeouts set
  http_status="$(
    curl -sS -L \
      --connect-timeout 10 --max-time 30 \
      -H "User-Agent: ${UA}" \
      -w "%{http_code}" -o "$TMP_FILE" \
      "$API_URL" || echo "000"
  )"

  if [[ "${http_status}" =~ ^2 ]]; then
    mv "$TMP_FILE" "$OUT_FILE"
    echo "Saved to ${OUT_FILE}"
    exit 0
  else
    # Read a short preview of the response body (useful for 4xx/5xx messages)
    preview="$(head -c 200 "$TMP_FILE" 2>/dev/null || true)"
    rm -f "$TMP_FILE"

    if (( attempt < RETRIES )) && [[ "$http_status" =~ ^(000|429|5..)$ ]]; then
      # retry on network error (000), rate limit (429), or server errors (5xx)
      sleep_seconds=$(( attempt * 2 ))
      log_error "Attempt ${attempt}/${RETRIES} failed (HTTP ${http_status}) for ${API_URL}. Retrying in ${sleep_seconds}s. Body: ${preview}"
      sleep "$sleep_seconds"
      ((attempt++))
      continue
    fi

    log_error "Failed to fetch ${API_URL} (HTTP ${http_status}). Body: ${preview}"
    echo "Error logged to ${ERR_FILE}" >&2
    exit 1
  fi
done
