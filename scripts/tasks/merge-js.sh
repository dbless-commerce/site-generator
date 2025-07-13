#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "$PARENT_DIR/utils/utils.sh"

set_error_handling

JS_SOURCE_FILE="files/js/main.js"
OUTPUT_JS_NAME="site.js"
STATIC_DIR_NAME="static"

validate_js_source() {
    if [ ! -f "$JS_SOURCE_FILE" ]; then
        error "JavaScript source file not found: $JS_SOURCE_FILE"
        return 1
    fi
    
    if [ ! -s "$JS_SOURCE_FILE" ]; then
        warn "JavaScript source file is empty: $JS_SOURCE_FILE"
        return 1
    fi
    
    return 0
}

get_file_size() {
    local file="$1"
    if command -v stat >/dev/null 2>&1; then
        stat -f%z "$file" 2>/dev/null || \
        stat -c%s "$file" 2>/dev/null || \
        echo "unknown"
    else
        echo "unknown"
    fi
}

merge_js_for_site() {
    local folder="$1"
    
    if ! validate_directory "$folder"; then
        warn "Site directory $folder not found, skipping..."
        return 1
    fi
    
    progress "Merging JavaScript for: $folder"
    
    local static_dir="$folder/$STATIC_DIR_NAME"
    local output_file="$static_dir/$OUTPUT_JS_NAME"
    
    ensure_directory "$static_dir"
    
    local main_content
    if ! main_content=$(cat "$JS_SOURCE_FILE" 2>/dev/null); then
        error "Failed to read JavaScript source file: $JS_SOURCE_FILE"
        return 1
    fi
    
    if echo "$main_content" > "$output_file" 2>/dev/null; then
        local file_size=$(get_file_size "$output_file")
        local line_count=$(wc -l < "$output_file" 2>/dev/null || echo "unknown")
        
        info "✅ Merged JavaScript for $folder"
        debug "   File: $output_file"
        debug "   Size: ${file_size} bytes"
        debug "   Lines: ${line_count}"
        return 0
    else
        error "Failed to write JavaScript file: $output_file"
        return 1
    fi
}

validate_merged_files() {
    local processed_sites=("$@")
    local validation_errors=0
    
    print_section "Validating Merged Files"
    
    for folder in "${processed_sites[@]}"; do
        local output_file="$folder/$STATIC_DIR_NAME/$OUTPUT_JS_NAME"
        
        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            info "✓ $output_file - Valid"
        else
            error "✗ $output_file - Invalid or empty"
            ((validation_errors++))
        fi
    done
    
    if [ $validation_errors -eq 0 ]; then
        success "All merged files validated successfully"
        return 0
    else
        error "$validation_errors validation errors found"
        return 1
    fi
}

main() {
    start_timer
    
    print_banner "JavaScript Merge Script"
    
    log "Starting JavaScript merge process for all language sites..."
    
    if ! validate_js_source; then
        error "JavaScript source validation failed."
        exit 1
    fi
    
    local site_folders=()
    while IFS= read -r folder; do
        if [ -n "$folder" ]; then
            site_folders+=("$folder")
        fi
    done < <(find . -maxdepth 1 -type d -name 'site-*' -printf '%P\n' 2>/dev/null || true)
    
    if [ ${#site_folders[@]} -eq 0 ]; then
        error "No site-* directories found. Please run the build process first."
        exit 1
    fi
    
    print_section "Found Site Directories"
    for folder in "${site_folders[@]}"; do
        info "  - $folder"
    done
    
    print_section "JavaScript Source"
    local source_size=$(get_file_size "$JS_SOURCE_FILE")
    local source_lines=$(wc -l < "$JS_SOURCE_FILE" 2>/dev/null || echo "unknown")
    info "  - Source: $JS_SOURCE_FILE"
    info "  - Size: ${source_size} bytes"
    info "  - Lines: ${source_lines}"
    info "  - Output: $STATIC_DIR_NAME/$OUTPUT_JS_NAME"
    
    local processed_sites=()
    local failed_sites=()
    
    for folder in "${site_folders[@]}"; do
        if merge_js_for_site "$folder"; then
            processed_sites+=("$folder")
        else
            failed_sites+=("$folder")
        fi
    done
    
    if [ ${#processed_sites[@]} -gt 0 ]; then
        validate_merged_files "${processed_sites[@]}"
    fi
    
    echo ""
    if [ ${#processed_sites[@]} -gt 0 ]; then
        print_summary "JavaScript Merge Process" "${processed_sites[@]}"
    fi
    
    if [ ${#failed_sites[@]} -gt 0 ]; then
        warn "Failed to process sites: ${failed_sites[*]}"
    fi
    
    end_timer "JavaScript merge process"
    
    if [ ${#processed_sites[@]} -eq 0 ]; then
        error "No JavaScript files were merged successfully!"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
