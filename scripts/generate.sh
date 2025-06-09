#!/bin/bash

folders=$(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n')
for folder in $folders; do
    echo "${folder##*-}"
done