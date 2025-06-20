#!/bin/bash

generate_html() {
    local lang="$1"
    local title="$2"
    local description="$3"
    local keywords="$4"

    cat << EOF
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta name="keywords" content="${keywords}">
  <link rel="stylesheet" href="/site.css"/>
  <link rel="icon" href="/favicon.png" type="image/png"/>
</head>
<body>
  <div id="loading">loading...</div>
  <footer></footer>
  <script src="static/site.js"></script>
</body>
</html>
EOF
}

folders=$(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n')
for folder in $folders; do
    
    lang="${folder##*-}"
    echo "Processing folder: $folder with language: $lang"

    echo "Processing folder: $folder with language: $lang"

    site_json_path="./${folder}/data/site.json"

    if [[ -f "$site_json_path" ]]; then
        site_json=$(cat "$site_json_path")   

        pages=$(echo "$site_json" | jq -r '.pages | keys[]')
        for page in $pages; do
            page_title=$(echo "$site_json" | jq -r ".pages[\"$page\"].title")
            page_description=$(echo "$site_json" | jq -r ".pages[\"$page\"].description")
            page_keywords=$(echo "$site_json" | jq -r ".pages[\"$page\"].keywords")
            page_url=$(echo "$site_json" | jq -r ".pages[\"$page\"].url // \"$page\"")
            output_file="./${folder}/${page_url}.html"

            

            generate_html "$lang" "$page_title" "$page_description" "$page_keywords" > "$output_file"
        done
        
        echo "HTML files created in $folder"

    else
        echo "Warning: $site_json_path not found, skipping folder $folder"
    fi
    
done

