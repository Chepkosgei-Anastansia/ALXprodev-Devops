#!/usr/bin/env bash
# data_extraction_automation-0x01.sh
# Extract and format Pokémon data from a JSON file.
# Usage: ./data_extraction_automation-0x01.sh [data_file]
set -euo pipefail
FILE="${1:-data.json}"

jq -r '
  # capitalize helper
  def cap: if type=="string" and length>0
           then (.[0:1]|ascii_upcase) + .[1:]
           else .
           end;

  .name    as $n         # e.g., "pikachu"
  | .height as $h        # decimetres
  | .weight as $w        # hectograms
  | ([.types[].type.name] | map(cap) | join("/")) as $t  # e.g., "Electric"

  # Convert units: height dm→m, weight hg→kg
  | "\(( $n|cap)) is of type \($t), weighs \(( $w/10)|tostring)kg, and is \(( $h/10)|tostring)m tall."
' "$FILE"
