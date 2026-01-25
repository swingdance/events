#!/bin/bash

set -euo pipefail

INPUT_JSON_FILE=${1:-}

CURRENT_YEAR="$(date +%Y)"
DATE_FORMAT="%Y-%m-%d"
 
process_json_file() {
  local json_file="$1"
  local date_starts date_ends year month

  date_starts="$(jq -r '.date_starts' "$json_file")"
  date_ends="$(jq -r '.date_ends' "$json_file")"

  if ! year="$(date -j -f "$DATE_FORMAT" "$date_starts" "+%Y")"; then
    echo "Skipping $json_file: invalid date_starts format: $date_starts" >&2
    return 0
  fi

  # Skip if year is equal or greater than CURRENT_YEAR.
  #
  if [[ "$year" -ge "$CURRENT_YEAR" ]]; then
    return 0
  fi

  month="$(date -j -f "$DATE_FORMAT" "$date_starts" "+%m")"
  increased_placeholder="$CURRENT_YEAR-$month-01"

  # Reset date_starts and date_ends value to "$CURRENT_YEAR-$month-01"
  #   if date is unavailable (date_starts == date_ends and day == 01).
  #
  local day; day="${date_starts:8}"
  if [[ "$date_starts" == "$date_ends" ]] && [[ "$day" == "01" ]]; then
    tmp="$(mktemp)"
    jq --arg ds "$increased_placeholder" '.date_starts = $ds | .date_ends = $ds' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
    return 0
  fi

  # Backup & reset
  #
  # Backup $date_starts & $date_end into an array field named: "past",
  #  this array contains element in string, e.g., "2025-02-21_02-23".
  past_element="${date_starts}_${date_ends#????-}"
  tmp="$(mktemp)"
  jq --arg entry "$past_element" '.past = (.past // []) + [$entry]' "$json_file" > "$tmp" && mv "$tmp" "$json_file"

  # Reset date_starts and date_ends value to "$CURRENT_YEAR-$month-01".
  tmp="$(mktemp)"
  jq --arg ds "$increased_placeholder" '.date_starts = $ds | .date_ends = $ds' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
}

# If an input JSON file was provided and exists, process it.
#
if [[ -n "$INPUT_JSON_FILE" ]]; then
  if [[ -f "$INPUT_JSON_FILE" ]]; then
    process_json_file "$INPUT_JSON_FILE"
  else
    echo "Input file not found: $INPUT_JSON_FILE" >&2
  fi
# Otherwise enumerate all *.json files in regions.
#
else
  while read -r json_file; do
    process_json_file "$json_file"
  done < <(find "regions" -type f -name '*.json' | sort)
fi

echo
echo "DONE"
echo

exit 0
