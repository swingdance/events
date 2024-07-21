#!/bin/bash

set -e

while read -r a_year_folder; do
  year="$(basename "$a_year_folder")"
  echo "- YEAR: $year"

  while read -r a_region_folder; do
    region="$(basename "$a_region_folder")"
    echo "- - REGION: $region"

    while read -r an_evnet_json_file; do
      event_id="$(jq -r ".id" "$an_evnet_json_file")"
      if [ "$event_id" = "_template" ]; then
        continue
      fi
      renamed_event_id="${event_id}-${year}"
      renamed_event_file="$a_region_folder/$renamed_event_id.json"
      jq --arg jq_key "id" --arg jq_value "$renamed_event_id" '.[$jq_key] = $jq_value' "$an_evnet_json_file" > "$renamed_event_file"
      rm "$an_evnet_json_file"
    done < <(find "$a_region_folder" -name "*.json" -type f)
    
  done < <(find "$a_year_folder" -mindepth 1 -maxdepth 1 -type d -name "??" | sort)
  # done < <(find "$a_year_folder" -mindepth 1 -maxdepth 1 -type d -regex "^.*_.*" | sort)

done < <(find "." -mindepth 1 -maxdepth 1 -type d -regex ".*/[0-9].*" | sort)
