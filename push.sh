#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "No commit message argument passed"
  exit 1
fi

# Find all files greater than 50MB (excluding .git directory) and split them into parts
part_files=()
while IFS= read -r -d '' file; do
  echo "Splitting $file into parts..."
  split -b 25M "$file" "$file.part"
  part_files+=($(ls "$file.part"*))
done < <(find . $(printf " -path ./%s -o" $(cat .findignore)) -prune -o -type f -size +50M -print0)

# Add .part files to the Git index
echo "Adding .part files to Git index..."
for part_file in "${part_files[@]}"
do
  git add "$part_file"
done

# Find all files greater than 50MB and append them to .gitignore
find . $(printf " -path ./%s -o" $(cat .findignore)) -prune -o -type f -size +50M -print0 | while read -d $'\0' file; do
    if ! grep -qxF "$file" .gitignore; then
        echo "$file" >> .gitignore
    fi
done

# Add all files to the Git index
git add .

git commit -m "$1"

git push -u origin main
