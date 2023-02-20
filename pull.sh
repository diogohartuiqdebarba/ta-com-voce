#!/bin/bash

git pull

# Find all split files and group them by original file name
#split_files=( $(find . -type f -name '*.part*' | sort) )
split_files=( $(find . $(printf " -path ./%s -o" $(cat .findignore)) -prune -o -type f -size +50M -print0) )

original_files=( $(echo "${split_files[@]}" | tr ' ' '\n' | grep -o '.*\.[^.]+' | sort -u) )

# Loop through each group of split files and concatenate them back into the original file
for split_file in "${split_files[@]}"; do
  if [[ "${split_file}" =~ ^(.+)\.part[a-z]+$ ]]; then
    original_file="${BASH_REMATCH[1]}"
    file_parts=( $(echo "${split_files[@]}" | tr ' ' '\n' | grep "${original_file}.part[a-z]*" | sort) )

    echo "original_file=${original_file}"
    echo "file_parts=${file_parts[@]}"
    # Check if all parts are present before concatenating
    all_parts_present=true
    for file_part in "${file_parts[@]}"; do
      if [[ ! -f "${file_part}" ]]; then
        all_parts_present=false
        break
      fi
    done

    if [[ "${all_parts_present}" = true ]]; then
      cat "${file_parts[@]}" > "${original_file}"
      echo "Restored ${original_file}"
    else
      echo "Not all parts are present for ${original_file}"
    fi
  fi
done