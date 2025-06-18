#!/bin/bash

folders=$(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n')
for folder in $folders; do
    
    mkdir -p "$folder/static/img"
    cp files/img/*.png "$folder/static/img/"


    cp files/logo.jpg "$folder/logo.jpg"
    cp files/favicon.png "$folder/favicon.png"
    
done


