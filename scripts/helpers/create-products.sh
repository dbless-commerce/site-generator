#!/bin/bash

# Enhanced Product Pages Generator - Using Shared Components
# Generates individual product pages using shared HTML generators

# Get script directory and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

source "$PARENT_DIR/shared/utils.sh"
source "$PARENT_DIR/shared/html-generators.sh"
source "$PARENT_DIR/shared/product-generators.sh"

# Set up error handling
set_error_handling

# Initialize language-specific directories and set global variables
init_language() {
    local lang="$1"
    
    # Set global variables for shared functions
    export CURRENT_LANG="$lang"
    export DATA_DIR="./site-${lang}/data"
    export OUTPUT_DIR="./site-${lang}"
    export PRODUCTS_DIR="$OUTPUT_DIR/products"
    
    debug "Initialized language: $lang"
    debug "Data directory: $DATA_DIR"
    debug "Products directory: $PRODUCTS_DIR"
}

# Generate product page HTML using shared generators
generate_product_html() {
    local product_data="$1"
    local lang="$2"
    
    # Extract product information
    local name=$(get_json_value "$product_data" "name" "Product")
    local url=$(get_json_value "$product_data" "url" "product")
    local meta_desc=$(get_json_value "$product_data" "metaDesc" "")
    local meta_keywords=$(get_json_value "$product_data" "keywords" "")
    
    # Load site and company data for this language
    local site_data=$(load_json "site" "$DATA_DIR")
    local company_data=$(load_json "company" "$DATA_DIR")
    local products_data=$(load_json "products" "$DATA_DIR")
    
    # Get company name for title
    local company_name=$(get_json_value "$company_data" "name" "Website")
    local title="$name | $company_name"
    
    # Generate page components using shared functions
    local page_subtitle=$(generate_page_subtitle "product")
    local product_detail=$(generate_product_detail_content "$product_data" "$site_data")
    local products_list=$(generate_products_list "$products_data" "$site_data" 4 true)
    
    # Generate the complete HTML structure
    cat << EOF
<!DOCTYPE html>
<html lang="$lang">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <link rel="stylesheet" href="/site.css">
    <meta name="description" content="$meta_desc">
    <meta name="keywords" content="$meta_keywords">
    <link rel="icon" href="/favicon.png" type="image/png">
</head>
<body>
    $(generate_header "product")
    <main>
$page_subtitle
$product_detail
$products_list
    </main>
    $(generate_footer)
</body>
</html>
EOF
}

# Process products for a single language
process_language_products() {
    local lang="$1"
    
    # Check if language directory exists
    if ! validate_directory "./site-${lang}"; then
        warn "Language directory ./site-${lang} not found, skipping..."
        return 1
    fi
    
    # Initialize language settings
    init_language "$lang"
    
    # Validate products.json exists
    local products_file="$DATA_DIR/products.json"
    if ! validate_json "$products_file"; then
        warn "Products file not found or invalid for $lang, skipping..."
        return 1
    fi
    
    progress "Processing products for language: $lang"
    
    # Clean and create products directory
    clean_directory "$PRODUCTS_DIR"
    ensure_directory "$PRODUCTS_DIR"
    
    # Load products data
    local products_data=$(load_json "products" "$DATA_DIR")
    
    # Check if products array exists
    if ! echo "$products_data" | jq -e '.products | type == "array"' > /dev/null 2>&1; then
        warn "No products array found in $products_file"
        return 1
    fi
    
    # Process each product
    local product_count=0
    while IFS= read -r product; do
        if [ -n "$product" ]; then
            local decoded=$(echo "$product" | base64 -d 2>/dev/null || echo '{}')
            local url=$(get_json_value "$decoded" "url" "")
            local name=$(get_json_value "$decoded" "name" "")
            
            if [ -n "$url" ] && [ -n "$name" ]; then
                local output_file="$PRODUCTS_DIR/$url.html"
                
                debug "Creating product page: $url.html"
                generate_product_html "$decoded" "$lang" > "$output_file"
                
                ((product_count++))
                info "✓ Created $url.html"
            else
                warn "Skipping product with missing url or name"
            fi
        fi
    done < <(get_json_array "$products_data" "products")
    
    success "Generated $product_count product pages for $lang"
    return 0
}

# Main function
main() {
    start_timer
    
    print_banner "Product Pages Generator"
    
    # Check dependencies
    if ! check_dependencies "jq"; then
        exit 1
    fi
    
    log "Starting product pages generation for all languages..."
    
    # Find all language directories
    local processed_languages=()
    local failed_languages=()
    
    for lang in "${LANGUAGES[@]}"; do
        print_section "Processing Language: $(echo $lang | tr '[:lower:]' '[:upper:]')"
        
        if process_language_products "$lang"; then
            processed_languages+=("$lang")
        else
            failed_languages+=("$lang")
        fi
    done
    
    # Print summary
    echo ""
    if [ ${#processed_languages[@]} -gt 0 ]; then
        print_summary "Product Pages Generation" "${processed_languages[@]}"
    fi
    
    if [ ${#failed_languages[@]} -gt 0 ]; then
        warn "Failed to process languages: ${failed_languages[*]}"
    fi
    
    end_timer "Product pages generation"
    
    if [ ${#processed_languages[@]} -eq 0 ]; then
        error "No product pages were generated!"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
