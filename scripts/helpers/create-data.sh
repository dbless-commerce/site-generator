#!/bin/bash

# Find all site-* folders
folders=$(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n')

for folder in $folders; do
    echo "Processing $folder"

    # Extract language code from folder name (e.g., site-tr -> tr)
    lang=${folder#site-}

    # Remove the existing data folder
    rm -rf "$folder/data"

    # Copy files/data/<lang>/ into site-*/data/
    cp -r "files/data/$lang" "$folder/data"

done
