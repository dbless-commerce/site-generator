#!/bin/bash

# Enhanced Multi-Language HTML Generation Script - COMPLETE SYSTEM

set -e

# Configuration
BASE_DIR="."
STATIC_DIR="./static"
LANGUAGES=("ar" "tr" "en")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Global variables for current language processing
CURRENT_LANG=""
DATA_DIR=""
OUTPUT_DIR=""

# Initialize language-specific directories
init_language() {
    local lang="$1"
    CURRENT_LANG="$lang"
    DATA_DIR="./site-${lang}/data"
    OUTPUT_DIR="./site-${lang}"
    
    log "Processing language: $lang"
    log "Data directory: $DATA_DIR"
    log "Output directory: $OUTPUT_DIR"
    
    # Clean everything except data folder
    find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 ! -name 'data' -exec rm -rf {} + 2>/dev/null || true
    
    # Copy static files for this language
    if [ -d "$STATIC_DIR" ]; then
        cp -r "$STATIC_DIR" "$OUTPUT_DIR/"
    fi
    
    # Copy language-specific static files if they exist
    if [ -d "./site-${lang}/static" ]; then
        cp -r "./site-${lang}/static/"* "$OUTPUT_DIR/static/" 2>/dev/null || true
    fi
}

# Load data files with proper error handling and validation
load_json() {
    local file="$1"
    local json_file="$DATA_DIR/$file.json"
    
    if [ -f "$json_file" ]; then
        # Validate JSON and escape properly for shell processing
        if jq empty "$json_file" 2>/dev/null; then
            # Use jq to properly escape and format the JSON
            jq -c . "$json_file" 2>/dev/null || echo "{}"
        else
            error "Invalid JSON in file: $json_file"
            echo "{}"
        fi
    else
        warn "Data file not found: $json_file"
        echo "{}"
    fi
}

# Generate logo HTML
generate_logo() {
    local company_data=$(load_json "company")
    local slogan=$(echo "$company_data" | jq -r '.slogan // ""' 2>/dev/null || echo "")
    
    echo "<img src=\"/logo.jpg\" alt=\"$slogan\" title=\"$slogan\" class=\"logo\" />"
}

# Generate navigation menu - ENHANCED with proper menu items
generate_navigation() {
    local site_data=$(load_json "site")
    local current_page="$1"
    local menu_items=""
    
    # Check if navigation array exists in site.json
    if echo "$site_data" | jq -e '.navigation | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r nav_item; do
            if [ -n "$nav_item" ]; then
                local nav_data=$(echo "$nav_item" | base64 -d 2>/dev/null || echo '{}')
                local nav_title=$(echo "$nav_data" | jq -r '.title // ""' 2>/dev/null || echo "")
                local nav_url=$(echo "$nav_data" | jq -r '.url // ""' 2>/dev/null || echo "")
                local nav_key=$(echo "$nav_data" | jq -r '.key // ""' 2>/dev/null || echo "")
                
                local active_class=""
                if [ "$current_page" = "$nav_key" ]; then
                    active_class=" active"
                fi
                
                if [ -n "$nav_title" ] && [ -n "$nav_url" ]; then
                    menu_items="${menu_items}            <li class=\"menu-item${active_class}\" data-url=\"${nav_url}\" onclick=\"navigateTo(this)\">${nav_title}</li>\n"
                fi
            fi
        done < <(echo "$site_data" | jq -r '.navigation[]? | @base64' 2>/dev/null || true)
    else
        # Fallback to basic navigation
        local home_text=$(echo "$site_data" | jq -r '.home // "Home"' 2>/dev/null || echo "Home")
        local products_text=$(echo "$site_data" | jq -r '.products // "Products"' 2>/dev/null || echo "Products")
        local about_text=$(echo "$site_data" | jq -r '.about // "About"' 2>/dev/null || echo "About")
        local story_text=$(echo "$site_data" | jq -r '.story // "Story"' 2>/dev/null || echo "Story")
        local contact_text=$(echo "$site_data" | jq -r '.contact // "Contact"' 2>/dev/null || echo "Contact")
        
        local nav_items=(
            "home:/:$home_text"
            "urunlerimiz:/urunlerimiz.html:$products_text"
            "hakkimizda:/hakkimizda.html:$about_text"
            "lezzetimizin-hikayesi:/lezzetimizin-hikayesi.html:$story_text"
            "iletisim:/iletisim.html:$contact_text"
        )
        
        for item in "${nav_items[@]}"; do
            IFS=':' read -r key url title <<< "$item"
            local active_class=""
            if [ "$current_page" = "$key" ]; then
                active_class=" active"
            fi
            menu_items="${menu_items}            <li class=\"menu-item${active_class}\" data-url=\"${url}\" onclick=\"navigateTo(this)\">${title}</li>\n"
        done
    fi
    
    echo -e "$menu_items"
}

# Generate basket info HTML
generate_basket_info() {
    local site_data=$(load_json "site")
    local basket_text=$(echo "$site_data" | jq -r '.basketText // "Basket"' 2>/dev/null || echo "Basket")
    
    cat << EOF
    <div id="basketInfo">
        <div></div>
        <img src="/static/img/basket.png" alt="$basket_text" />
        <em></em>
    </div>
EOF
}

# Generate basket section HTML
generate_basket_section() {
    local site_data=$(load_json "site")
    local basket_warning=$(echo "$site_data" | jq -r '.basketWarning // "Basket functionality"' 2>/dev/null || echo "Basket functionality")
    local show_basket=$(echo "$site_data" | jq -r '.showBasket // "Show Basket"' 2>/dev/null || echo "Show Basket")
    local empty_basket=$(echo "$site_data" | jq -r '.emptyBasket // "Empty Basket"' 2>/dev/null || echo "Empty Basket")
    
    cat << EOF
    <div id="basket">
        <p>$basket_warning</p>
        <button id="btnShowBasket">$show_basket</button>
        <button id="btnEmptyBasket" style="display: none;">$empty_basket</button>
        <ul></ul>
    </div>
EOF
}

# Generate header - ENHANCED with proper navigation structure
generate_header() {
    local company_data=$(load_json "company")
    local site_data=$(load_json "site")
    local current_page="${1:-home}"
    
    local company_name=$(echo "$company_data" | jq -r '.name // "Website"' 2>/dev/null || echo "Website")
    local company_desc=$(echo "$company_data" | jq -r '.description // ""' 2>/dev/null || echo "")
    local logo_html=$(generate_logo)
    local menu_text=$(echo "$site_data" | jq -r '.menuText // "Menu"' 2>/dev/null || echo "Menu")
    local navigation_html=$(generate_navigation "$current_page")
    
    cat << EOF
<!DOCTYPE html>
<html lang="$CURRENT_LANG">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$company_name</title>
    <link rel="stylesheet" href="/site.css">
    <meta name="description" content="$company_desc">
</head>
<body>
    <header>
        <div class="logo" onclick="window.location.href='/' + window.location.search">
            $logo_html
        </div>
    </header>
    <nav>
        <menu>
            <li class="menu-toggle" data-open="false" onclick="toggleMenu(this)">
                <img src="/static/img/menu.png" alt="$menu_text" />
            </li>
$navigation_html        </menu>
    </nav>
EOF
}

# Generate footer image section
generate_footer_image_section() {
    local site_data=$(load_json "site")
    local company_data=$(load_json "company")
    
    local footer_slogan_start=$(echo "$site_data" | jq -r '.footImgSloganStart // ""' 2>/dev/null || echo "")
    local footer_slogan_end=$(echo "$site_data" | jq -r '.footImgSloganEnd // ""' 2>/dev/null || echo "")
    local footer_button=$(echo "$site_data" | jq -r '.footSloganBtn // "More"' 2>/dev/null || echo "")
    local footer_link=$(echo "$site_data" | jq -r '.footSloganLnk // "#"' 2>/dev/null || echo "")
    local company_slogan=$(echo "$company_data" | jq -r '.slogan // ""' 2>/dev/null || echo "")
    
    cat << EOF
        <div class="bigImg">
            <img src="/static/img/pages/footer.jpg" alt="$company_slogan">
            <div>
                <em>$footer_slogan_start</em>
                <em>$footer_slogan_end</em>
                <button onclick="window.location.href='$footer_link' + window.location.search">
                    $footer_button
                </button>
            </div>
        </div>
EOF
}

# Generate footer social section
generate_footer_social_section() {
    local company_data=$(load_json "company")
    local company_phone=$(echo "$company_data" | jq -r '.phone // ""' 2>/dev/null || echo "")
    local company_instagram=$(echo "$company_data" | jq -r '.instagram // "#"' 2>/dev/null || echo "#")
    
    cat << EOF
        <div class="social">
            <a href="$company_instagram" target="_blank">
                <img src="/static/img/instagram.png" alt="instagram" />
            </a>
            <a href="#" onclick="openWhatsApp('$company_phone')">
                <img src="/static/img/whatsapp.png" alt="whatsapp" />
            </a>
        </div>
EOF
}

# Generate footer links section
generate_footer_links_section() {
    local site_data=$(load_json "site")
    local footer_links=""
    
    if echo "$site_data" | jq -e '.footerLinks | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r link_item; do
            if [ -n "$link_item" ]; then
                local link_data=$(echo "$link_item" | base64 -d 2>/dev/null || echo '{}')
                local link_title=$(echo "$link_data" | jq -r '.title // ""' 2>/dev/null || echo "")
                local link_url=$(echo "$link_data" | jq -r '.url // ""' 2>/dev/null || echo "")
                
                if [ -n "$link_title" ] && [ -n "$link_url" ]; then
                    footer_links="${footer_links}        <a href=\"${link_url}\">${link_title}</a>\n"
                fi
            fi
        done < <(echo "$site_data" | jq -r '.footerLinks[]? | @base64' 2>/dev/null || true)
    else
        # Fallback footer links
        local distance_sales=$(echo "$site_data" | jq -r '.distanceSalesAlt // "Distance Sales Agreement"' 2>/dev/null || echo "Distance Sales Agreement")
        local kvkk=$(echo "$site_data" | jq -r '.kvkk // "KVKK"' 2>/dev/null || echo "KVKK")
        local privacy=$(echo "$site_data" | jq -r '.privacyAlt // "Privacy Policy"' 2>/dev/null || echo "Privacy Policy")
        local sitemap=$(echo "$site_data" | jq -r '.sitemap // "Site Map"' 2>/dev/null || echo "Site Map")
        
        footer_links="        <a href=\"/satis-sozlesmesi.html\">$distance_sales</a>\n"
        footer_links="${footer_links}        <a href=\"/kvkk.html\">$kvkk</a>\n"
        footer_links="${footer_links}        <a href=\"/gizlilik-politikasi.html\">$privacy</a>\n"
        footer_links="${footer_links}        <a href=\"/site-haritasi.html\">$sitemap</a>\n"
    fi
    
    echo -e "$footer_links"
}

# Generate page subtitle (h3) for all pages except home - FIXED
generate_page_subtitle() {
    local page_key="$1"
    local site_data=$(load_json "site")
    
    # Don't show subtitle on home page
    if [ "$page_key" = "home" ] || [ "$page_key" = "index" ]; then
        echo ""
        return
    fi
    
    local page_subtitle=$(echo "$site_data" | jq -r '.pageSubtitle // ""' 2>/dev/null || echo "")
    
    if [ -n "$page_subtitle" ]; then
        echo "        <h3>$page_subtitle</h3>"
    fi
}

# Generate footer - ENHANCED with proper structure
generate_footer() {
    local company_data=$(load_json "company")
    local site_data=$(load_json "site")
    local current_year=$(date +%Y)
    
    local company_name=$(echo "$company_data" | jq -r '.name // ""' 2>/dev/null || echo "")
    local company_email=$(echo "$company_data" | jq -r '.email // ""' 2>/dev/null || echo "")
    
    local footer_image_section=$(generate_footer_image_section)
    local footer_social_section=$(generate_footer_social_section)
    local footer_links_section=$(generate_footer_links_section)
    local footer_logo=$(generate_logo)
    local basket_info=$(generate_basket_info)
    local basket_section=$(generate_basket_section)
    
    cat << EOF
$basket_info
$basket_section
    <footer>
$footer_image_section
        <br/><br/>
$footer_social_section
        <br/><br/>
        <a href="mailto:$company_email">$company_email</a>
        <p>$company_name © $current_year</p>
        <br/>
$footer_links_section
        $footer_logo
    </footer>
    <script src="static/site.js"></script>
</body>
</html>
EOF
}

# Generate product card - ENHANCED with proper basket functionality
generate_product_card() {
    local product="$1"
    local is_linked="${2:-true}"
    
    local id=$(echo "$product" | jq -r '.id // ""' 2>/dev/null || echo "")
    local name=$(echo "$product" | jq -r '.name // ""' 2>/dev/null || echo "")
    local url=$(echo "$product" | jq -r '.url // ""' 2>/dev/null || echo "")
    local price=$(echo "$product" | jq -r '.price // 0' 2>/dev/null || echo "0")
    local short_desc=$(echo "$product" | jq -r '.shortDesc // ""' 2>/dev/null || echo "")
    
    local site_data=$(load_json "site")
    local vat_included=$(echo "$site_data" | jq -r '.vatIncluded // "(VAT Included)"' 2>/dev/null || echo "(VAT Included)")
    local add_to_basket=$(echo "$site_data" | jq -r '.addToBasket // "Add to Basket"' 2>/dev/null || echo "Add to Basket")
    
    if [ -n "$id" ] && [ -n "$name" ] && [ -n "$url" ]; then
        cat << EOF
        <li data-id="$id">
            <img src="/static/img/products/$url.jpg" alt="$name" data-url="$url"$([ "$is_linked" = "true" ] && echo ' onclick="navigateToProduct(this)"') />
            <h2 data-url="$url"$([ "$is_linked" = "true" ] && echo ' onclick="navigateToProduct(this)"')>$name</h2>
            <strong>$price TL <em>$vat_included</em></strong>
$([ "$is_linked" = "true" ] && echo "            <p>$short_desc</p>")
            <button class="btnAddToBasket" onclick="fnAddToBasket.call(this)">$add_to_basket</button>
            <br/>
        </li>
EOF
    fi
}

# Generate products list - ENHANCED
generate_products_list() {
    local products_data=$(load_json "products")
    local limit="${1:-4}"
    local is_linked="${2:-true}"
    
    echo "    <ul id=\"products\">"
    
    if echo "$products_data" | jq -e '.products | type == "array"' > /dev/null 2>&1; then
        local count=0
        while IFS= read -r product && [ $count -lt $limit ]; do
            if [ -n "$product" ]; then
                local decoded=$(echo "$product" | base64 -d 2>/dev/null || echo '{}')
                if [ -n "$decoded" ] && [ "$decoded" != "{}" ]; then
                    generate_product_card "$decoded" "$is_linked"
                    ((count++))
                fi
            fi
        done < <(echo "$products_data" | jq -r '.products[]? | @base64' 2>/dev/null || true)
    fi
    
    echo "    </ul>"
}

# Generate sitemap links - ENHANCED
generate_sitemap_links() {
    local site_data=$(load_json "site")
    local links=""
    
    if echo "$site_data" | jq -e '.sitemapLinks | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r link_item; do
            if [ -n "$link_item" ]; then
                local link_data=$(echo "$link_item" | base64 -d 2>/dev/null || echo '{}')
                local link_title=$(echo "$link_data" | jq -r '.title // ""' 2>/dev/null || echo "")
                local link_url=$(echo "$link_data" | jq -r '.url // ""' 2>/dev/null || echo "")
                
                if [ -n "$link_title" ] && [ -n "$link_url" ]; then
                    links="${links}            <a href=\"${link_url}\">${link_title}</a>\n"
                fi
            fi
        done < <(echo "$site_data" | jq -r '.sitemapLinks[]? | @base64' 2>/dev/null || true)
    fi
    
    echo -e "$links"
}

# Generate page content from JSON - COMPLETELY ENHANCED for complex structure
generate_page_content() {
    local page_key="$1"
    local site_data=$(load_json "site")
    local content=""
    
    # Check if page has content in the pages object
    local page_content=$(echo "$site_data" | jq -r ".pages[\"$page_key\"].content // {}" 2>/dev/null || echo "{}")
    
    if [ "$page_content" != "{}" ] && [ -n "$page_content" ]; then
        # Handle sections array
        if echo "$page_content" | jq -e '.sections | type == "array"' > /dev/null 2>&1; then
            while IFS= read -r section; do
                if [ -n "$section" ]; then
                    local decoded_section=$(echo "$section" | base64 -d 2>/dev/null || echo '{}')
                    local section_title=$(echo "$decoded_section" | jq -r '.title // ""' 2>/dev/null || echo "")
                    local section_text=$(echo "$decoded_section" | jq -r '.text // ""' 2>/dev/null || echo "")
                    local additional_text=$(echo "$decoded_section" | jq -r '.additionalText // ""' 2>/dev/null || echo "")
                    local list_type=$(echo "$decoded_section" | jq -r '.listType // "ul"' 2>/dev/null || echo "ul")
                    
                    # Add title as h2 element
                    if [ -n "$section_title" ]; then
                        content="${content}            <h2>${section_title}</h2>\n"
                    fi
                    
                    # Add main text as p element
                    if [ -n "$section_text" ]; then
                        content="${content}            <p>${section_text}</p>\n"
                    fi
                    
                    # Handle lists (ordered or unordered)
                    if echo "$decoded_section" | jq -e '.list | type == "array"' > /dev/null 2>&1; then
                        # Determine list type (ul for unordered, ol for ordered)
                        local list_tag="ul"
                        if [ "$list_type" = "ol" ] || [ "$list_type" = "ordered" ]; then
                            list_tag="ol"
                        fi
                        
                        content="${content}            <${list_tag} class=\"list\">\n"
                        while IFS= read -r item; do
                            if [ -n "$item" ]; then
                                content="${content}                <li>${item}</li>\n"
                            fi
                        done < <(echo "$decoded_section" | jq -r '.list[]?' 2>/dev/null || true)
                        content="${content}            </${list_tag}>\n"
                    fi
                    
                    # Add additional text if present
                    if [ -n "$additional_text" ]; then
                        content="${content}            <p>${additional_text}</p>\n"
                    fi
                fi
            done < <(echo "$page_content" | jq -r '.sections[]? | @base64' 2>/dev/null || true)
        fi
    fi
    
    echo -e "$content"
}

# Generate 404 page - WITH PRODUCTS AND SUBTITLE
generate_404_page() {
    log "Generating 404 page for $CURRENT_LANG..."
    
    local site_data=$(load_json "site")
    local not_found_title=$(echo "$site_data" | jq -r '.pageNotFoundTitle // "Page Not Found"' 2>/dev/null || echo "Page Not Found")
    local not_found_message=$(echo "$site_data" | jq -r '.pageNotFoundMessage // "The page you are looking for was not found."' 2>/dev/null || echo "The page you are looking for was not found.")
    local products_list=$(generate_products_list 4 true)
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

# Generate contact page - WITH PRODUCTS AND SUBTITLE
generate_contact_page() {
    local company_data=$(load_json "company")
    local site_data=$(load_json "site")
    
    log "Generating contact page for $CURRENT_LANG..."
    
    local contact_title=$(echo "$site_data" | jq -r '.contact // "Contact"' 2>/dev/null || echo "Contact")
    local map_text=$(echo "$site_data" | jq -r '.map // "View on Map"' 2>/dev/null || echo "View on Map")
    local company_name=$(echo "$company_data" | jq -r '.name // ""' 2>/dev/null || echo "")
    local legal_name=$(echo "$company_data" | jq -r '.legalName // .name // ""' 2>/dev/null || echo "")
    local phone=$(echo "$company_data" | jq -r '.phone // ""' 2>/dev/null || echo "")
    local phone_clean=$(echo "$phone" | tr -d ' ')
    local email=$(echo "$company_data" | jq -r '.email // ""' 2>/dev/null || echo "")
    local map_link=$(echo "$company_data" | jq -r '.mapLink // "https://maps.app.goo.gl/4mFyGQx7jfX2S2vh7"' 2>/dev/null || echo "https://maps.app.goo.gl/4mFyGQx7jfX2S2vh7")
    local page_subtitle=$(generate_page_subtitle "iletisim")
    
    # Generate address from array
    local address_block=""
    if echo "$company_data" | jq -e '.address | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                address_block="${address_block}                    ${line}<br/>"
            fi
        done < <(echo "$company_data" | jq -r '.address[]?' 2>/dev/null || true)
    fi
    
    local products_list=$(generate_products_list 4 true)
    
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

# Generate site map page - WITH PRODUCTS AND SUBTITLE
generate_sitemap_page() {
    local site_data=$(load_json "site")
    
    log "Generating site map page for $CURRENT_LANG..."
    
    local sitemap_title=$(echo "$site_data" | jq -r '.sitemap // "Site Map"' 2>/dev/null || echo "Site Map")
    local sitemap_links=$(generate_sitemap_links)
    local products_list=$(generate_products_list 4 true)
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

# Generate home page - WITH HERO AND PRODUCTS (NO SUBTITLE)
generate_home_page() {
    local site_data=$(load_json "site")
    local company_data=$(load_json "company")
    
    log "Generating home page for $CURRENT_LANG..."
    
    local company_slogan=$(echo "$company_data" | jq -r '.slogan // ""' 2>/dev/null || echo "")
    local head_slogan_start=$(echo "$site_data" | jq -r '.headImgSloganStart // ""' 2>/dev/null || echo "")
    local head_slogan_end=$(echo "$site_data" | jq -r '.headImgSloganEnd // ""' 2>/dev/null || echo "")
    local head_link=$(echo "$site_data" | jq -r '.headSloganLnk // "#"' 2>/dev/null || echo "#")
    local head_button=$(echo "$site_data" | jq -r '.headSloganBtn // "More"' 2>/dev/null || echo "More")
    local products_list=$(generate_products_list 4 true)
    
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

# Generate products page - DEDICATED PRODUCTS PAGE WITH SUBTITLE
generate_products_page() {
    local company_data=$(load_json "company")
    local site_data=$(load_json "site")
    
    log "Generating products page for $CURRENT_LANG..."
    
    local company_slogan=$(echo "$company_data" | jq -r '.slogan // ""' 2>/dev/null || echo "")
    local products_list=$(generate_products_list 999 true)
    local page_subtitle=$(generate_page_subtitle "urunlerimiz")
    
    {
        generate_header "urunlerimiz"
        cat << EOF
    <main>
$page_subtitle
$products_list
    </main>
EOF
        generate_footer
    } > "$OUTPUT_DIR/urunlerimiz.html"
}

# Generate individual product pages - WITH PRODUCTS LIST AND SUBTITLE
generate_product_pages() {
    local products_data=$(load_json "products")
    
    log "Generating product pages for $CURRENT_LANG..."
    mkdir -p "$OUTPUT_DIR/products"
    
    if echo "$products_data" | jq -e '.products | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r product; do
            if [ -n "$product" ]; then
                local decoded=$(echo "$product" | base64 -d 2>/dev/null || echo '{}')
                local url=$(echo "$decoded" | jq -r '.url // ""' 2>/dev/null || echo "")
                local name=$(echo "$decoded" | jq -r '.name // ""' 2>/dev/null || echo "")
                local long_desc=$(echo "$decoded" | jq -r '.longDesc | join(" ") // ""' 2>/dev/null || echo "")
                
                if [ -n "$url" ] && [ -n "$name" ]; then
                    local product_card=$(generate_product_card "$decoded" false)
                    local products_list=$(generate_products_list 4 true)
                    local page_subtitle=$(generate_page_subtitle "product")
                    
                    {
                        generate_header "product"
                        cat << EOF
    <main>
$page_subtitle
        <article class="prd">
$product_card
            <p style="text-align: justify;">$long_desc</p>
        </article>
$products_list
    </main>
EOF
                        generate_footer
                    } > "$OUTPUT_DIR/products/$url.html"
                fi
            fi
        done < <(echo "$products_data" | jq -r '.products[]? | @base64' 2>/dev/null || true)
    fi
}

# Generate static pages from data - WITH PRODUCTS AND ENHANCED CONTENT
generate_static_pages() {
    local site_data=$(load_json "site")
    
    log "Generating static pages for $CURRENT_LANG..."
    
    if echo "$site_data" | jq -e '.pages | type == "object"' > /dev/null 2>&1; then
        while IFS= read -r page_key; do
            if [ -n "$page_key" ] && [ "$page_key" != "index" ] && [ "$page_key" != "iletisim" ] && [ "$page_key" != "site-haritasi" ] && [ "$page_key" != "404" ]; then
                local page_data=$(echo "$site_data" | jq -r ".pages[\"$page_key\"] // {}" 2>/dev/null || echo "{}")
                local title=$(echo "$page_data" | jq -r '.title // ""' 2>/dev/null || echo "")
                
                if [ -n "$title" ]; then
                    local page_title=$(echo "$title" | cut -d'|' -f1 | xargs)
                    local page_content=$(generate_page_content "$page_key")
                    local products_list=$(generate_products_list 4 true)
                    local page_subtitle=$(generate_page_subtitle "$page_key")
                    
                    {
                        generate_header "$page_key"
                        cat << EOF
    <main>
$page_subtitle
        <article>
            <h2>$page_title</h2>
            <img src="/static/img/pages/$page_key.jpg" alt="$page_title" style="object-position: center;" />
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
    if [ ! -d "./site-${lang}" ]; then
        warn "Language directory ./site-${lang} not found, skipping..."
        return
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
    
    log "Completed generation for language: $lang"
}

# Generate main language selection index
generate_main_index() {
    log "Generating main language selection index..."
    
    cat << 'EOF' > "./index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=width=device-width, initial-scale=1.0">
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
    log "Starting multi-language HTML generation..."
    
    # Check dependencies
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed. Please install jq."
        exit 1
    fi
    
    # Process each language
    for lang in "${LANGUAGES[@]}"; do
        process_language "$lang"
    done
    
    # Generate main language selection index
    generate_main_index
    
    log "Multi-language HTML generation completed successfully!"
    log "Generated sites in language folders:"
    for lang in "${LANGUAGES[@]}"; do
        if [ -d "./site-${lang}" ]; then
            log "  - $lang: ./site-${lang}/"
        fi
    done
}

# Run main function
main "$@"
