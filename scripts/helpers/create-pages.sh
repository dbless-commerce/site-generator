#!/bin/bash

# Enhanced Multi-Language HTML Generation Script - Using Shared Components

# Get script directory and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "$PARENT_DIR/shared/utils.sh"
source "$PARENT_DIR/shared/html-generators.sh"
source "$PARENT_DIR/shared/product-generators.sh"

# Set up error handling
set_error_handling

# Initialize language-specific directories and set global variables for shared functions
init_language() {
    local lang="$1"
    
    # Set global variables for shared functions
    export CURRENT_LANG="$lang"
    export DATA_DIR="./site-${lang}/data"
    export OUTPUT_DIR="./site-${lang}"
    
    log "Processing language: $lang"
    debug "Data directory: $DATA_DIR"
    debug "Output directory: $OUTPUT_DIR"
    
    # Clean everything except data folder
    clean_directory "$OUTPUT_DIR" "data"
    
    # Copy static files for this language
    copy_static_files "$STATIC_DIR" "$OUTPUT_DIR" "$lang"
}

# Generate 404 page
generate_404_page() {
    log "Generating 404 page for $CURRENT_LANG..."
    
    local site_data=$(load_json "site" "$DATA_DIR")
    local products_data=$(load_json "products" "$DATA_DIR")
    local not_found_title=$(get_json_value "$site_data" "pageNotFoundTitle" "Page Not Found")
    local not_found_message=$(get_json_value "$site_data" "pageNotFoundMessage" "The page you are looking for was not found.")
    local products_list=$(generate_products_list "$products_data" "$site_data" 4 true)
    local page_subtitle=$(generate_page_subtitle "404")
    
    {
        generate_header "404"
        cat << EOF
    <main>
$page_subtitle
        <article>
            <h2>$not_found_title</h2>
            <img src="/static/img/pages/404.jpg" alt="$not_found_title" style="object-position: center;" />
            <p>$not_found_message</p>
            <br/>
        </article>
$products_list
    </main>
EOF
        generate_footer
    } > "$OUTPUT_DIR/404.html"
}

# Generate contact page
generate_contact_page() {
    local company_data=$(load_json "company" "$DATA_DIR")
    local site_data=$(load_json "site" "$DATA_DIR")
    local products_data=$(load_json "products" "$DATA_DIR")
    
    log "Generating contact page for $CURRENT_LANG..."
    
    local contact_title=$(get_json_value "$site_data" "contact" "Contact")
    local map_text=$(get_json_value "$site_data" "map" "View on Map")
    local company_name=$(get_json_value "$company_data" "name" "")
    local legal_name=$(get_json_value "$company_data" "legalName" "$(get_json_value "$company_data" "name" "")")
    local phone=$(get_json_value "$company_data" "phone" "")
    local phone_clean=$(echo "$phone" | tr -d ' ')
    local email=$(get_json_value "$company_data" "email" "")
    local map_link=$(get_json_value "$company_data" "mapLink" "https://maps.app.goo.gl/4mFyGQx7jfX2S2vh7")
    local page_subtitle=$(generate_page_subtitle "iletisim")
    
    # Generate address from array
local address_block=""
if echo "$company_data" | jq -e '.address | type == "array"' > /dev/null 2>&1; then
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            # decode base64 before appending
            decoded_line=$(echo "$line" | base64 --decode)
            address_block="${address_block}                    ${decoded_line}<br/>"
        fi
    done < <(get_json_array "$company_data" "address")
fi

    
    local products_list=$(generate_products_list "$products_data" "$site_data" 4 true)
    
    {
        generate_header "iletisim"
        cat << EOF
    <main>
$page_subtitle
        <article>
            <h2>$contact_title</h2>
            <img src="/static/img/pages/iletisim.jpg" alt="$company_name" style="object-position: center;" />
            <em>$legal_name</em>
            <br/>
            <div class="contact">
                <img src="/static/img/address.png" alt="address" />
                <address>
$address_block                </address>
                <br/>
                <img src="/static/img/map.png" alt="map" />
                <a href="$map_link" target="_blank">$map_text</a>
                <br/>
                <img src="/static/img/phone.png" alt="phone" />
                <a href="tel:$phone_clean">$phone</a>
                <br/>
                <img src="/static/img/email.png" alt="email" />
                <a href="mailto:$email">$email</a>
            </div>
        </article>
$products_list
    </main>
EOF
        generate_footer
    } > "$OUTPUT_DIR/iletisim.html"
}

# Generate site map page
generate_sitemap_page() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local products_data=$(load_json "products" "$DATA_DIR")
    
    log "Generating site map page for $CURRENT_LANG..."
    
    local sitemap_title=$(get_json_value "$site_data" "sitemap" "Site Map")
    local sitemap_links=$(generate_sitemap_links)
    local products_list=$(generate_products_list "$products_data" "$site_data" 4 true)
    local page_subtitle=$(generate_page_subtitle "site-haritasi")
    
    {
        generate_header "site-haritasi"
        cat << EOF
    <main>
$page_subtitle
        <article>
            <h2>$sitemap_title</h2>
            <img src="/static/img/pages/site-haritasi.jpg" alt="$sitemap_title" style="object-position: bottom;" />
            <br/>
$sitemap_links
            <br/>
        </article>
$products_list
    </main>
EOF
        generate_footer
    } > "$OUTPUT_DIR/site-haritasi.html"
}

# Generate home page
generate_home_page() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local company_data=$(load_json "company" "$DATA_DIR")
    local products_data=$(load_json "products" "$DATA_DIR")
    
    log "Generating home page for $CURRENT_LANG..."
    
    local company_slogan=$(get_json_value "$company_data" "slogan" "")
    local head_slogan_start=$(get_json_value "$site_data" "headImgSloganStart" "")
    local head_slogan_end=$(get_json_value "$site_data" "headImgSloganEnd" "")
    local head_link=$(get_json_value "$site_data" "headSloganLnk" "#")
    local head_button=$(get_json_value "$site_data" "headSloganBtn" "More")
    local products_list=$(generate_products_list "$products_data" "$site_data" 4 true)
    
    {
        generate_header "home"
        cat << EOF
    <div class="bigImg" style="margin-top: -48px;">
        <img src="/static/img/pages/header.jpg" alt="$company_slogan">
        <div>
            <em>$head_slogan_start</em>
            <em>$head_slogan_end</em>
            <button onclick="window.location.href='$head_link' + window.location.search">
                $head_button
            </button>
        </div>
    </div>
    <main>
$products_list
    </main>
EOF
        generate_footer
    } > "$OUTPUT_DIR/index.html"
}

# Generate products page
generate_products_page() {
    local company_data=$(load_json "company" "$DATA_DIR")
    local site_data=$(load_json "site" "$DATA_DIR")
    local products_data=$(load_json "products" "$DATA_DIR")
    
    log "Generating products page for $CURRENT_LANG..."
    
    local company_slogan=$(get_json_value "$company_data" "slogan" "")
    local products_list=$(generate_products_list "$products_data" "$site_data" 999 true)
    local page_subtitle=$(generate_page_subtitle "urunlerimiz")
    
    {
        generate_header "urunlerimiz"
        cat << EOF
    <main>
$page_subtitle
        <h3>$company_slogan</h3>
$products_list
    </main>
EOF
        generate_footer
    } > "$OUTPUT_DIR/urunlerimiz.html"
}

# Generate individual product pages
generate_product_pages() {
    local products_data=$(load_json "products" "$DATA_DIR")
    local site_data=$(load_json "site" "$DATA_DIR")
    
    log "Generating product pages for $CURRENT_LANG..."
    ensure_directory "$OUTPUT_DIR/products"
    
    if echo "$products_data" | jq -e '.products | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r product; do
            if [ -n "$product" ]; then
                local decoded=$(echo "$product" | base64 -d 2>/dev/null || echo '{}')
                local url=$(get_json_value "$decoded" "url" "")
                local name=$(get_json_value "$decoded" "name" "")
                
                if [ -n "$url" ] && [ -n "$name" ]; then
                    local product_detail=$(generate_product_detail_content "$decoded" "$site_data")
                    local products_list=$(generate_products_list "$products_data" "$site_data" 4 true)
                    local page_subtitle=$(generate_page_subtitle "product")
                    
                    {
                        generate_header "product"
                        cat << EOF
    <main>
$page_subtitle
$product_detail
$products_list
    </main>
EOF
                        generate_footer
                    } > "$OUTPUT_DIR/products/$url.html"
                fi
            fi
        done < <(get_json_array "$products_data" "products")
    fi
}

# Generate static pages from data
generate_static_pages() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local products_data=$(load_json "products" "$DATA_DIR")

    log "Generating static pages for $CURRENT_LANG..."

    if echo "$site_data" | jq -e '.pages | type == "object"' > /dev/null 2>&1; then
        while IFS= read -r page_key; do
            if [ -n "$page_key" ] && [ "$page_key" != "index" ] && [ "$page_key" != "iletisim" ] && [ "$page_key" != "site-haritasi" ] && [ "$page_key" != "404" ]; then
                local page_data=$(echo "$site_data" | jq -r ".pages[\"$page_key\"] // {}" 2>/dev/null || echo "{}")
                local title=$(get_json_value "$page_data" "title" "")

                if [ -n "$title" ]; then
                    local page_title=$(echo "$title" | cut -d'|' -f1 | xargs)
                    local page_content=$(generate_page_content "$page_key")
                    local products_list=$(generate_products_list "$products_data" "$site_data" 4 true)
                    local page_subtitle=$(generate_page_subtitle "$page_key")
                    local image_tag=""

                    if [[ "$page_title" != "Our Products" &&  "$page_title" != "منتجاتنا"  &&  "$page_title" != "Ürünlerimiz"  ]]; then
                        image_tag="            <img src=\"/static/img/pages/$page_key.jpg\" alt=\"$page_title\" style=\"object-position: center;\" />"
                    fi

                    {
                        generate_header "$page_key"
                        cat << EOF
    <main>
$page_subtitle
        <article>
            <h2>$page_title</h2>
$image_tag
$page_content
        </article>
$products_list
    </main>
EOF
                        generate_footer
                    } > "$OUTPUT_DIR/$page_key.html"
                fi
            fi
        done < <(echo "$site_data" | jq -r '.pages | keys[]?' 2>/dev/null || true)
    fi
}

# Process single language
process_language() {
    local lang="$1"
    
    # Check if language directory exists
    if ! validate_directory "./site-${lang}"; then
        warn "Language directory ./site-${lang} not found, skipping..."
        return 1
    fi
    
    # Initialize language-specific settings
    init_language "$lang"
    
    # Generate all pages for this language
    generate_home_page
    generate_products_page
    generate_product_pages
    generate_contact_page
    generate_sitemap_page
    generate_404_page
    generate_static_pages
    
    success "Completed generation for language: $lang"
    return 0
}

# Generate main language selection index
generate_main_index() {
    log "Generating main language selection index..."
    
    cat << 'EOF' > "./index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Select Language / Dil Seçin / اختر اللغة</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .language-selector {
            background: white;
            padding: 3rem;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            text-align: center;
        }
        .language-selector h1 {
            margin-bottom: 2rem;
            color: #333;
        }
        .language-links {
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
            justify-content: center;
        }
        .language-link {
            display: block;
            padding: 1rem 2rem;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            transition: all 0.3s ease;
            font-weight: bold;
        }
        .language-link:hover {
            background: #764ba2;
            transform: translateY(-2px);
        }
        .flag {
            font-size: 1.5rem;
            margin-right: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="language-selector">
        <h1>Select Your Language</h1>
        <div class="language-links">
            <a href="./site-en/" class="language-link">
                <span class="flag">🇺🇸</span>English
            </a>
            <a href="./site-tr/" class="language-link">
                <span class="flag">🇹🇷</span>Türkçe
            </a>
            <a href="./site-ar/" class="language-link">
                <span class="flag">🇸🇦</span>العربية
            </a>
        </div>
    </div>
</body>
</html>
EOF
}

# Main build function
main() {
    start_timer
    
    print_banner "Multi-Language HTML Generator"
    
    # Check dependencies
    if ! check_dependencies "jq"; then
        exit 1
    fi
    
    log "Starting multi-language HTML generation..."
    
    # Process each language
    local processed_languages=()
    local failed_languages=()
    
    for lang in "${LANGUAGES[@]}"; do
        print_section "Processing Language: $(echo $lang | tr '[:lower:]' '[:upper:]')"
        
        if process_language "$lang"; then
            processed_languages+=("$lang")
        else
            failed_languages+=("$lang")
        fi
    done
    
    # Generate main language selection index
    generate_main_index
    
    # Print summary
    if [ ${#processed_languages[@]} -gt 0 ]; then
        print_summary "HTML Generation" "${processed_languages[@]}"
    fi
    
    if [ ${#failed_languages[@]} -gt 0 ]; then
        warn "Failed to process languages: ${failed_languages[*]}"
    fi
    
    end_timer "Multi-language HTML generation"
    
    if [ ${#processed_languages[@]} -eq 0 ]; then
        error "No sites were generated!"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
