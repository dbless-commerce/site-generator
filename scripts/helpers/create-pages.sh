#!/bin/bash

# Get script directory and source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "$PARENT_DIR/shared/utils.sh"
source "$PARENT_DIR/shared/html-generators.sh"
source "$PARENT_DIR/shared/product-generators.sh"

set_error_handling

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
            <img src="/static/img/pages/404.jpg" alt="$not_found_title" class=\"centered-image;\" />
            <p>$not_found_message</p>
            <br/>
        </article>
$products_list
    </main>
EOF
        generate_footer
    } > "$OUTPUT_DIR/404.html"
}

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
            <img src="/static/img/pages/iletisim.jpg" alt="$company_name" class=\"centered-image;\" />
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
            <img src="/static/img/pages/site-haritasi.jpg" alt="$sitemap_title" class=\"bottom-image\" />
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
    <div class="bigImg" class=\"big-image\">
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
                        image_tag="            <img src=\"/static/img/pages/$page_key.jpg\" alt=\"$page_title\" class=\"centered-image;\" />"
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

process_language() {
    local lang="$1"
    
    if ! validate_directory "./site-${lang}"; then
        warn "Language directory ./site-${lang} not found, skipping..."
        return 1
    fi
    
    init_language "$lang"
    
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


main() {
    start_timer
    
    print_banner "Multi-Language HTML Generator"
    
    if ! check_dependencies "jq"; then
        exit 1
    fi
    
    log "Starting multi-language HTML generation..."
    
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
    
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
