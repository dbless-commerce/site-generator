#!/bin/bash

folders=$(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n')
for folder in $folders; do
echo $folder is the folders for langs

    rm -f "$folder/site.css"    
    cat "files/css/base.css" "files/css/footer.css" > "$folder/site.css"

    tmpfile=$(mktemp)
    tr -d '\n\t' < "$folder/site.css" | sed 's/  */ /g' > "$tmpfile" && mv "$tmpfile" "$folder/site.css"
    
done


