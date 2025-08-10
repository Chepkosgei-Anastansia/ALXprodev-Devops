#!/usr/bin/env bash
# batchProcessing-0x04.sh
# Batch process multiple Pokémon data fetches in parallel and save them to individual files.
# Usage: ./batchProcessing-0x04.sh


set -euo pipefail

POKEMON=(Bulbasaur Ivysaur Venusaur Charmander Charmeleon)
API_BASE="https://pokeapi.co/api/v2/pokemon"
OUT_DIR="pokemon_data"
ERR_FILE="errors.txt"
UA="pokefetch/1.0"

MAX_PROCS=3        # run up to N downloads at the same time
MAX_ATTEMPTS=3       # per-pokemon retries
CONNECT_TIMEOUT=10
TOTAL_TIMEOUT=30

mkdir -p "$OUT_DIR"
: > "$ERR_FILE"      # start fresh (remove this line if you want to append)

timestamp() { date -Iseconds; }

log_err() {
  # one-line log to minimize interleaving
  printf '[%s] %s\n' "$(timestamp)" "$1" >> "$ERR_FILE"
}

fetch_one() {
  local name="$1"
  local lower="${name,,}"
  local url="${API_BASE}/${lower}"
  local out="${OUT_DIR}/${lower}.json"

  local attempts=0 status tmp_file preview backoff
  echo "→ ${name}: start"

  while (( attempts < MAX_ATTEMPTS )); do
    attempts=$((attempts+1))
    tmp_file="$(mktemp)"

    status="$(
      curl -sS -L \
        --connect-timeout "$CONNECT_TIMEOUT" --max-time "$TOTAL_TIMEOUT" \
        -H "User-Agent: ${UA}" \
        -w "%{http_code}" -o "$tmp_file" \
        "$url" || echo "000"
    )"

    if [[ "$status" =~ ^2 ]]; then
      mv "$tmp_file" "$out"
      echo "✔ ${name}: saved → ${out}"
      return 0
    fi

    preview="$(head -c 120 "$tmp_file" 2>/dev/null || true)"
    rm -f "$tmp_file"

    # retry on network(000), 429, or 5xx
    if [[ "$status" == "000" || "$status" == "429" || "$status" =~ ^5..$ ]]; then
      if (( attempts < MAX_ATTEMPTS )); then
        backoff=$(( 2 * attempts ))   # 2s, 4s
        echo "… ${name}: attempt ${attempts}/${MAX_ATTEMPTS} failed (HTTP ${status}). retry in ${backoff}s"
        sleep "$backoff"
        continue
      fi
    fi

    log_err "${name} failed (HTTP ${status}) ${url} | ${preview}"
    echo "✖ ${name}: logged error"
    return 1
  done
}

# Ensure background jobs are cleaned up on Ctrl-C
trap 'echo; echo "Aborting…"; jobs -p | xargs -r kill 2>/dev/null || true; wait || true; exit 130' INT TERM

pids=()

for name in "${POKEMON[@]}"; do
  # throttle concurrency
  while (( $(jobs -r -p | wc -l) >= MAX_PROCS )); do
    sleep 0.2
  done

  fetch_one "$name" &
  pids+=( "$!" )
done

# Wait for all background jobs
fail_count=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    fail_count=$((fail_count+1))
  fi
done

echo "=== All downloads finished. Failures: ${fail_count} ==="

if (( fail_count > 0 )); then
  echo "Some downloads failed. Check ${ERR_FILE} for details."
else
  echo "All Pokémon data fetched successfully!"
fi
