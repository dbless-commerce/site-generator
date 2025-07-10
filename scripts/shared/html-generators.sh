#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

CURRENT_LANG="${CURRENT_LANG:-en}"
DATA_DIR="${DATA_DIR:-./data}"
OUTPUT_DIR="${OUTPUT_DIR:-./}"

generate_logo() {
    local company_data=$(load_json "company" "$DATA_DIR")
    local slogan=$(get_json_value "$company_data" "slogan" "")
    
    echo "<img src=\"/logo.jpg\" alt=\"$slogan\" title=\"$slogan\" class=\"logo\" />"
}

generate_navigation() {
    local current_page="$1"
    local site_data=$(load_json "site" "$DATA_DIR")
    local menu_items=""
    
    if echo "$site_data" | jq -e '.navigation | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r nav_item; do
            if [ -n "$nav_item" ]; then
                local nav_data=$(echo "$nav_item" | base64 -d 2>/dev/null || echo '{}')
                local nav_title=$(get_json_value "$nav_data" "title" "")
                local nav_url=$(get_json_value "$nav_data" "url" "")
                local nav_key=$(get_json_value "$nav_data" "key" "")
                
                local active_class=""
                if [ "$current_page" = "$nav_key" ]; then
                    active_class=" active"
                fi
                
                if [ -n "$nav_title" ] && [ -n "$nav_url" ]; then
                    menu_items="${menu_items}            <li class=\"menu-item${active_class}\" data-url=\"${nav_url}\" onclick=\"preserveBasketNavigation('${nav_url}')\">${nav_title}</li>\n"
                fi
            fi
        done < <(get_json_array "$site_data" "navigation")
    else
        local home_text=$(get_json_value "$site_data" "home" "Home")
        local products_text=$(get_json_value "$site_data" "products" "Products")
        local about_text=$(get_json_value "$site_data" "about" "About")
        local story_text=$(get_json_value "$site_data" "story" "Story")
        local contact_text=$(get_json_value "$site_data" "contact" "Contact")
        
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
            menu_items="${menu_items}            <li class=\"menu-item${active_class}\" data-url=\"${url}\" onclick=\"preserveBasketNavigation('${url}')\">${title}</li>\n"
        done
    fi
    
    echo -e "$menu_items"
}

generate_basket_info() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local basket_text=$(get_json_value "$site_data" "basketText" "Basket")
    
    cat << EOF
    <div id="basketInfo">
        <div></div>
        <img src="/static/img/basket.png" alt="$basket_text" />
        <em></em>
    </div>
EOF
}

generate_basket_section() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local basket_warning=$(get_json_value "$site_data" "basketWarning" "Basket functionality")
    local show_basket=$(get_json_value "$site_data" "showBasket" "Show Basket")
    local empty_basket=$(get_json_value "$site_data" "emptyBasket" "Empty Basket")
    
    cat << EOF
    <div id="basket">
        <p>$basket_warning</p>
        <button id="btnShowBasket">$show_basket</button>
        <button id="btnEmptyBasket" class="btn-empty-Basket">$empty_basket</button>
        <ul></ul>
    </div>
EOF
}

generate_header() {
    local current_page="${1:-home}"
    local company_data=$(load_json "company" "$DATA_DIR")
    local site_data=$(load_json "site" "$DATA_DIR")
    
    local company_name=$(get_json_value "$company_data" "name" "Website")
    local company_desc=$(get_json_value "$company_data" "description" "")
    local logo_html=$(generate_logo)
    local menu_text=$(get_json_value "$site_data" "menuText" "Menu")
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
        <div class="logo" onclick="preserveBasketNavigation('/')">
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

generate_footer_image_section() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local company_data=$(load_json "company" "$DATA_DIR")
    
    local footer_slogan_start=$(get_json_value "$site_data" "footImgSloganStart" "")
    local footer_slogan_end=$(get_json_value "$site_data" "footImgSloganEnd" "")
    local footer_button=$(get_json_value "$site_data" "footSloganBtn" "More")
    local footer_link=$(get_json_value "$site_data" "footSloganLnk" "#")
    local company_slogan=$(get_json_value "$company_data" "slogan" "")
    
    cat << EOF
        <div class="bigImg">
            <img src="/static/img/pages/footer.jpg" alt="$company_slogan">
            <div>
                <em>$footer_slogan_start</em>
                <em>$footer_slogan_end</em>
                <button onclick="preserveBasketNavigation('$footer_link')">
                    $footer_button
                </button>
            </div>
        </div>
EOF
}

generate_footer_social_section() {
    local company_data=$(load_json "company" "$DATA_DIR")
    local company_phone=$(get_json_value "$company_data" "phone" "")
    local company_instagram=$(get_json_value "$company_data" "instagram" "#")
    
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

generate_footer_links_section() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local footer_links=""
    
    if echo "$site_data" | jq -e '.footerLinks | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r link_item; do
            if [ -n "$link_item" ]; then
                local link_data=$(echo "$link_item" | base64 -d 2>/dev/null || echo '{}')
                local link_title=$(get_json_value "$link_data" "title" "")
                local link_url=$(get_json_value "$link_data" "url" "")
                
                if [ -n "$link_title" ] && [ -n "$link_url" ]; then
                    footer_links="${footer_links}        <a href=\"javascript:preserveBasketNavigation('${link_url}')\">${link_title}</a>\n"
                fi
            fi
        done < <(get_json_array "$site_data" "footerLinks")
    else
        local distance_sales=$(get_json_value "$site_data" "distanceSalesAlt" "Distance Sales Agreement")
        local kvkk=$(get_json_value "$site_data" "kvkk" "KVKK")
        local privacy=$(get_json_value "$site_data" "privacyAlt" "Privacy Policy")
        local sitemap=$(get_json_value "$site_data" "sitemap" "Site Map")
        
        footer_links="        <a href=\"javascript:preserveBasketNavigation('/satis-sozlesmesi.html')\">$distance_sales</a>\n"
        footer_links="${footer_links}        <a href=\"javascript:preserveBasketNavigation('/kvkk.html')\">$kvkk</a>\n"
        footer_links="${footer_links}        <a href=\"javascript:preserveBasketNavigation('/gizlilik-politikasi.html')\">$privacy</a>\n"
        footer_links="${footer_links}        <a href=\"javascript:preserveBasketNavigation('/site-haritasi.html')\">$sitemap</a>\n"
    fi
    
    echo -e "$footer_links"
}

generate_page_subtitle() {
    local page_key="$1"
    local site_data=$(load_json "site" "$DATA_DIR")
    
    if [ "$page_key" = "home" ] || [ "$page_key" = "index" ]; then
        echo ""
        return
    fi
    
    local page_subtitle=$(get_json_value "$site_data" "pageSubtitle" "")
    
    if [ -n "$page_subtitle" ]; then
        echo "        <h3>$page_subtitle</h3>"
    fi
}

generate_footer() {
    local company_data=$(load_json "company" "$DATA_DIR")
    local site_data=$(load_json "site" "$DATA_DIR")
    local current_year=$(date +%Y)
    
    local company_name=$(get_json_value "$company_data" "name" "")
    local company_email=$(get_json_value "$company_data" "email" "")
    
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
    <script src="/static/site.js"></script>
</body>
</html>
EOF
}

generate_sitemap_links() {
    local site_data=$(load_json "site" "$DATA_DIR")
    local links=""
    
    if echo "$site_data" | jq -e '.sitemapLinks | type == "array"' > /dev/null 2>&1; then
        while IFS= read -r link_item; do
            if [ -n "$link_item" ]; then
                local link_data=$(echo "$link_item" | base64 -d 2>/dev/null || echo '{}')
                local link_title=$(get_json_value "$link_data" "title" "")
                local link_url=$(get_json_value "$link_data" "url" "")
                
                if [ -n "$link_title" ] && [ -n "$link_url" ]; then
                    links="${links}            <a href=\"javascript:preserveBasketNavigation('${link_url}')\">${link_title}</a>\n"
                fi
            fi
        done < <(get_json_array "$site_data" "sitemapLinks")
    fi
    
    echo -e "$links"
}

generate_page_content() {
    local page_key="$1"
    local site_data=$(load_json "site" "$DATA_DIR")
    local content=""
    
    local page_content=$(echo "$site_data" | jq -r ".pages[\"$page_key\"].content // {}" 2>/dev/null || echo "{}")
    
    if [ "$page_content" != "{}" ] && [ -n "$page_content" ]; then
        if echo "$page_content" | jq -e '.sections | type == "array"' > /dev/null 2>&1; then
            while IFS= read -r section; do
                if [ -n "$section" ]; then
                    local decoded_section=$(echo "$section" | base64 -d 2>/dev/null || echo '{}')
                    local section_title=$(get_json_value "$decoded_section" "title" "")
                    local section_text=$(get_json_value "$decoded_section" "text" "")
                    local additional_text=$(get_json_value "$decoded_section" "additionalText" "")
                    local list_type=$(get_json_value "$decoded_section" "listType" "ul")
                    
                    if [ -n "$section_title" ]; then
                        content="${content}            <h2>${section_title}</h2>\n"
                    fi
                    
                    if [ -n "$section_text" ]; then
                        content="${content}            <p>${section_text}</p>\n"
                    fi
                    
                    if echo "$decoded_section" | jq -e '.list | type == "array"' > /dev/null 2>&1; then
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
                    
                    if [ -n "$additional_text" ]; then
                        content="${content}            <p>${additional_text}</p>\n"
                    fi
                fi
            done < <(get_json_array "$page_content" "sections")
        fi
    fi
    
    echo -e "$content"
}

export -f generate_logo generate_navigation generate_basket_info generate_basket_section
export -f generate_header generate_footer_image_section generate_footer_social_section
export -f generate_footer_links_section generate_page_subtitle generate_footer
export -f generate_sitemap_links generate_page_content
