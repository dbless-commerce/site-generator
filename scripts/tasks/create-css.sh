#!/bin/bash

# Get script directory and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "$PARENT_DIR/utils/utils.sh"

# Set up error handling
set_error_handling

# Configuration
CSS_BASE_FILE="files/css/base.css"
CSS_FOOTER_FILE="files/css/footer.css"
CSS_HEADER_FILE="files/css/header.css"
CSS_PRODUCT_FILE="files/css/product.css"
CSS_BASKET_FILE="files/css/basket.css"
CSS_LAYOUT_FILE="files/css/layout.css"
CSS_RESPONSIVE_FILE="files/css/responsive.css"
OUTPUT_CSS_NAME="site.css"

validate_css_sources() {
    local missing_files=()
    
    if [ ! -f "$CSS_BASE_FILE" ]; then
        missing_files+=("$CSS_BASE_FILE")
    fi
    
    if [ ! -f "$CSS_FOOTER_FILE" ]; then
        missing_files+=("$CSS_FOOTER_FILE")
    fi

    if [ ! -f "$CSS_HEADER_FILE" ]; then
        missing_files+=("$CSS_HEADER_FILE")
    fi

    if [ ! -f "$CSS_PRODUCT_FILE" ]; then
        missing_files+=("$CSS_PRODUCT_FILE")
    fi

    if [ ! -f "$CSS_BASKET_FILE" ]; then
        missing_files+=("$CSS_BASKET_FILE")
    fi

    if [ ! -f "$CSS_LAYOUT_FILE" ]; then
        missing_files+=("$CSS_LAYOUT_FILE")
    fi

    if [ ! -f "$CSS_RESPONSIVE_FILE" ]; then
        missing_files+=("$CSS_RESPONSIVE_FILE")
    fi

    if [ ${#missing_files[@]} -gt 0 ]; then
        error "Missing CSS source files:"
        for file in "${missing_files[@]}"; do
            error "  - $file"
        done
        return 1
    fi
    
    return 0
}

optimize_css() {
    local input_file="$1"
    local output_file="$2"
    
    if [ ! -f "$input_file" ]; then
        error "Input CSS file not found: $input_file"
        return 1
    fi
    
    local tmpfile=$(mktemp)
    
    if tr -d '\n\t' < "$input_file" | sed 's/  */ /g' > "$tmpfile"; then
        if mv "$tmpfile" "$output_file"; then
            debug "✓ Optimized CSS: $output_file"
            return 0
        else
            error "Failed to move optimized CSS to: $output_file"
            rm -f "$tmpfile"
            return 1
        fi
    else
        error "Failed to optimize CSS: $input_file"
        rm -f "$tmpfile"
        return 1
    fi
}

create_css_for_site() {
    local folder="$1"
    
    if ! validate_directory "$folder"; then
        warn "Site directory $folder not found, skipping..."
        return 1
    fi
    
    progress "Creating CSS for: $folder"
    
    local output_file="$folder/$OUTPUT_CSS_NAME"
    local temp_merged=$(mktemp)
    
    if [ -f "$output_file" ]; then
        rm -f "$output_file"
        debug "Removed existing CSS file: $output_file"
    fi
    
    # Merge CSS files
    if cat \
        "$CSS_BASE_FILE" \
        "$CSS_FOOTER_FILE" \
        "$CSS_HEADER_FILE" \
        "$CSS_PRODUCT_FILE" \
        "$CSS_BASKET_FILE" \
        "$CSS_LAYOUT_FILE" \
        "$CSS_RESPONSIVE_FILE" > "$temp_merged" 2>/dev/null; then

        debug "✓ Merged CSS files successfully"
        
        if optimize_css "$temp_merged" "$output_file"; then
            local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "unknown")
            info "✅ Created optimized CSS for $folder (${file_size} bytes)"
            rm -f "$temp_merged"
            return 0
        else
            error "Failed to optimize CSS for $folder"
            rm -f "$temp_merged"
            return 1
        fi
    else
        error "Failed to merge CSS files for $folder"
        rm -f "$temp_merged"
        return 1
    fi
}

# Main function
main() {
    start_timer
    
    print_banner "CSS Creation Script"
    
    log "Starting CSS creation process for all language sites..."
    
    if ! validate_css_sources; then
        error "CSS source validation failed. Please ensure all required files exist."
        exit 1
    fi
    
    # Find all site directories
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
    
    print_section "CSS Source Files"
    info "  - Base CSS: $CSS_BASE_FILE"
    info "  - Footer CSS: $CSS_FOOTER_FILE"
    info "  - Header CSS: $CSS_HEADER_FILE"
    info "  - Product CSS: $CSS_PRODUCT_FILE"
    info "  - Basket CSS: $CSS_BASKET_FILE"
    info "  - Layout CSS: $CSS_LAYOUT_FILE"
    info "  - Responsive CSS: $CSS_RESPONSIVE_FILE"
    info "  - Output: $OUTPUT_CSS_NAME (optimized)"
    
    # Process each site directory
    local processed_sites=()
    local failed_sites=()
    
    for folder in "${site_folders[@]}"; do
        if create_css_for_site "$folder"; then
            processed_sites+=("$folder")
        else
            failed_sites+=("$folder")
        fi
    done
    
    # Print summary
    echo ""
    if [ ${#processed_sites[@]} -gt 0 ]; then
        print_summary "CSS Creation Process" "${processed_sites[@]}"
    fi
    
    if [ ${#failed_sites[@]} -gt 0 ]; then
        warn "Failed to process sites: ${failed_sites[*]}"
    fi
    
    end_timer "CSS creation process"
    
    if [ ${#processed_sites[@]} -eq 0 ]; then
        error "No CSS files were created successfully!"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
