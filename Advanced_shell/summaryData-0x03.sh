#!/usr/bin/env bash
# summaryData-0x03.sh
# Summarize Pokémon data from multiple JSON files into a CSV report.
# Usage: ./summaryData-0x03.sh

set -euo pipefail

IN_DIR="pokemon_data"
OUT_CSV="pokemon_report.csv"

# Require jq
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required."; exit 1; }

# Ensure there are JSON files to read
shopt -s nullglob
files=( "$IN_DIR"/*.json )
if [ ${#files[@]} -eq 0 ]; then
  echo "No JSON files found in $IN_DIR. Run Task 2 first."
  exit 1
fi

# Header
echo "name,height_m,weight_kg" > "$OUT_CSV"

# Extract per file: name (Capitalized), height dm->m, weight hg->kg
for f in "${files[@]}"; do
  jq -r '
    def cap:
      if type=="string" and length>0
      then (.[0:1]|ascii_upcase) + .[1:]
      else .
      end;
    "\((.name|cap)),\((.height/10)),\((.weight/10))"
  ' "$f" >> "$OUT_CSV"
done

echo "CSV Report generated at:$OUT_CSV"

# Averages with awk (skip header)
awk -F, 'NR>1 {h+=$2; w+=$3; n++} END {
  if (n>0) {
    printf "Average height (m): %.2f\nAverage weight (kg): %.2f\n", h/n, w/n
  } else {
    print "No data rows in CSV"
  }
}' "$OUT_CSV" >> "$OUT_CSV"
