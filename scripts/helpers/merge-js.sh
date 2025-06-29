#!/usr/bin/env bash

# Read content of JS files
main_content=$(cat programmatic/main.js)

# Merge into each site-*/static/site.js
folders=$(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n')
for folder in $folders; do
  output_file="${folder}/static/site.js"
  mkdir -p "$(dirname "$output_file")" 
  echo "$main_content" > "$output_file"
  echo "✅ Merged files into $output_file"
done
