#!/usr/bin/env bash

# Read content of JS files
helper_content=$(cat programmatic/helper.js)
basket_content=$(cat programmatic/basket.js)
pages_content=$(cat programmatic/pages.js)
product_content=$(cat programmatic/product.js)
main_content=$(cat programmatic/main.js)

# Merge into each site-*/static/site.js
folders=$(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n')
for folder in $folders; do
  output_file="${folder}/static/site.js"
  mkdir -p "$(dirname "$output_file")" 
  echo "$main_content" > "$output_file"
  echo "$helper_content" >> "$output_file"
  echo "$basket_content" >> "$output_file"
  echo "$pages_content" >> "$output_file"
  echo "$product_content" >> "$output_file"

  echo "✅ Merged files into $output_file"
done
