#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "$PARENT_DIR/shared/utils.sh"

set_error_handling

# Configuration
SOURCE_IMAGES_DIR="files/img"
SOURCE_PRODUCTS_DIR="files/products"
SOURCE_PAGES_DIR="files/img/pages"
SOURCE_LOGO="files/logo.jpg"
SOURCE_FAVICON="files/favicon.png"

validate_source_files() {
    local missing_files=()
    
    if [ ! -d "$SOURCE_IMAGES_DIR" ]; then
        missing_files+=("$SOURCE_IMAGES_DIR")
    fi
    
    if [ ! -d "$SOURCE_PRODUCTS_DIR" ]; then
        missing_files+=("$SOURCE_PRODUCTS_DIR")
    fi
    
    if [ ! -d "$SOURCE_PAGES_DIR" ]; then
        missing_files+=("$SOURCE_PAGES_DIR")
    fi
    
    if [ ! -f "$SOURCE_LOGO" ]; then
        missing_files+=("$SOURCE_LOGO")
    fi
    
    if [ ! -f "$SOURCE_FAVICON" ]; then
        missing_files+=("$SOURCE_FAVICON")
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        error "Missing source files/directories:"
        for file in "${missing_files[@]}"; do
            error "  - $file"
        done
        return 1
    fi
    
    return 0
}

copy_images_for_site() {
    local folder="$1"
    
    if ! validate_directory "$folder"; then
        warn "Site directory $folder not found, skipping..."
        return 1
    fi
    
    progress "Processing images for: $folder"
    
    local img_dirs=(
        "$folder/static/img"
        "$folder/static/img/pages"
        "$folder/static/img/products"
    )
    
    for dir in "${img_dirs[@]}"; do
        ensure_directory "$dir"
    done
    
    local copy_operations=(
        "$SOURCE_IMAGES_DIR/*.png:$folder/static/img/"
        "$SOURCE_PRODUCTS_DIR/*.jpg:$folder/static/img/products/"
        "$SOURCE_PAGES_DIR/*.jpg:$folder/static/img/pages/"
        "$SOURCE_LOGO:$folder/logo.jpg"
        "$SOURCE_FAVICON:$folder/favicon.png"
    )
    
    local success_count=0
    local total_operations=${#copy_operations[@]}
    
    for operation in "${copy_operations[@]}"; do
        IFS=':' read -r source target <<< "$operation"
        
        if cp $source "$target" 2>/dev/null; then
            ((success_count++))
            debug "✓ Copied $source to $target"
        else
            warn "Failed to copy $source to $target"
        fi
    done
    
    if [ $success_count -eq $total_operations ]; then
        info "✅ Successfully copied all images for $folder"
        return 0
    else
        warn "⚠️  Copied $success_count/$total_operations operations for $folder"
        return 1
    fi
}

# Main function
main() {
    start_timer
    
    print_banner "Image Copy Script"
    
    log "Starting image copy process for all language sites..."
    
    if ! validate_source_files; then
        error "Source validation failed. Please ensure all required files exist."
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

    local processed_sites=()
    local failed_sites=()
    
    for folder in "${site_folders[@]}"; do
        if copy_images_for_site "$folder"; then
            processed_sites+=("$folder")
        else
            failed_sites+=("$folder")
        fi
    done
    
    echo ""
    if [ ${#processed_sites[@]} -gt 0 ]; then
        print_summary "Image Copy Process" "${processed_sites[@]}"
    fi
    
    if [ ${#failed_sites[@]} -gt 0 ]; then
        warn "Failed to process sites: ${failed_sites[*]}"
    fi
    
    end_timer "Image copy process"
    
    if [ ${#processed_sites[@]} -eq 0 ]; then
        error "No images were copied successfully!"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
