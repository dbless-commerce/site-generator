#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/scripts/tasks/create-pages.sh"
bash "$SCRIPT_DIR/scripts/tasks/create-css.sh"
bash "$SCRIPT_DIR/scripts/tasks/create-products.sh"
bash "$SCRIPT_DIR/scripts/tasks/copy-images.sh"
bash "$SCRIPT_DIR/scripts/tasks/create-js.sh"
