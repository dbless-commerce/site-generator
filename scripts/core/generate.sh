#!/usr/bin/env bash

# Resolve the absolute path of the script and its parent
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

bash "$PARENT_DIR/tasks/create-pages.sh"
bash "$PARENT_DIR/tasks/create-css.sh"
bash "$PARENT_DIR/tasks/create-products.sh"
bash "$PARENT_DIR/tasks/copy-images.sh"
bash "$PARENT_DIR/tasks/merge-js.sh"
