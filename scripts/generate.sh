#!/usr/bin/env bash

bash scripts/helpers/create-css.
bash scripts/helpers/create-products.sh
bash scripts/helpers/copy-images.sh
bash scripts/helpers/create-pages.sh
bash scripts/helpers/merge-js.sh

