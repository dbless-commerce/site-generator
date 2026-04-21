#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() { 
    echo -e "${GREEN}[BUILD]${NC} $1" 
}

warn() { 
    echo -e "${YELLOW}[WARN]${NC} $1" 
}

error() { 
    echo -e "${RED}[ERROR]${NC} $1" 
}

info() { 
    echo -e "${BLUE}[INFO]${NC} $1" 
}

success() { 
    echo -e "${GREEN}[SUCCESS]${NC} $1" 
}

debug() { 
    if [ "${DEBUG:-}" = "1" ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1" 
    fi
}

progress() {
    echo -e "${CYAN}[PROGRESS]${NC} $1"
}

LANGUAGES=("ar" "tr" "en")
BASE_DIR="."
STATIC_DIR="./static"

validate_json() {
    local file="$1"
    if [ ! -f "$file" ]; then
        error "JSON file not found: $file"
        return 1
    fi
    
    if ! jq empty "$file" 2>/dev/null; then
        error "Invalid JSON in file: $file"
        return 1
    fi
    
    return 0
}

validate_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        error "Directory not found: $dir"
        return 1
    fi
    return 0
}

load_json() {
    local file="$1"
    local data_dir="$2"
    local json_file="$data_dir/$file.json"
    
    if validate_json "$json_file"; then
        jq -c . "$json_file" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

get_json_value() {
    local json="$1"
    local key="$2"
    local default="${3:-}"
    
    echo "$json" | jq -r ".$key // \"$default\"" 2>/dev/null || echo "$default"
}

get_json_array() {
    local json="$1"
    local key="$2"
    
    if echo "$json" | jq -e ".$key | type == \"array\"" > /dev/null 2>&1; then
        if [ "$key" = "longDesc" ]; then
            echo "$json" | jq -r ".$key[]?" 2>/dev/null || true
        else
            echo "$json" | jq -r ".$key[]? | @base64" 2>/dev/null || true
        fi
    fi
}

ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        debug "Created directory: $dir"
    fi
}

clean_directory() {
    local dir="$1"
    local preserve="$2"
    
    if [ -d "$dir" ]; then
        if [ -n "$preserve" ]; then
            find "$dir" -mindepth 1 -maxdepth 1 ! -name "$preserve" -exec rm -rf {} + 2>/dev/null || true
            debug "Cleaned directory $dir (preserved: $preserve)"
        else
            rm -rf "$dir"/*
            debug "Cleaned directory: $dir"
        fi
    fi
}

get_language_from_path() {
    local path="$1"
    echo "$path" | sed 's/.*site-$$[^/]*$$.*/\1/'
}

is_valid_language() {
    local lang="$1"
    for valid_lang in "${LANGUAGES[@]}"; do
        if [ "$lang" = "$valid_lang" ]; then
            return 0
        fi
    done
    return 1
}

copy_static_files() {
    local source_dir="$1"
    local target_dir="$2"
    local lang="$3"
    
    if [ -d "$source_dir" ]; then
        cp -r "$source_dir" "$target_dir/"
        debug "Copied static files from $source_dir to $target_dir"
    fi
    
    local lang_static="./site-${lang}/static"
    if [ -d "$lang_static" ]; then
        cp -r "$lang_static/"* "$target_dir/static/" 2>/dev/null || true
        debug "Copied language-specific static files for $lang"
    fi
}

check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        error "Please install the missing dependencies and try again."
        return 1
    fi
    
    return 0
}

start_timer() {
    TIMER_START=$(date +%s)
}

end_timer() {
    local operation="$1"
    local timer_end=$(date +%s)
    local duration=$((timer_end - TIMER_START))
    success "$operation completed in ${duration}s"
}

handle_error() {
    local exit_code=$?
    local line_number=$1
    error "Script failed at line $line_number with exit code $exit_code"
    exit $exit_code
}

set_error_handling() {
    set -e
    trap 'handle_error $LINENO' ERR
}

print_banner() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo ""
    printf "%*s\n" $width | tr ' ' '='
    printf "%*s%s%*s\n" $padding "" "$title" $padding ""
    printf "%*s\n" $width | tr ' ' '='
    echo ""
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${CYAN}▶ $title${NC}"
    echo "$(printf '%*s' ${#title} | tr ' ' '-')"
}

print_summary() {
    local operation="$1"
    shift
    local items=("$@")
    
    echo ""
    success "$operation Summary:"
    for item in "${items[@]}"; do
        echo "  ✓ $item"
    done
    echo ""
}
