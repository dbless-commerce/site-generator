#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
source "$PARENT_DIR/utils/utils.sh"

generate_product_card() {
    local product="$1"
    local site_data="$2"
    local is_linked="${3:-true}"
    
    local id=$(get_json_value "$product" "id" "")
    local name=$(get_json_value "$product" "name" "")
    local url=$(get_json_value "$product" "url" "")
    local price=$(get_json_value "$product" "price" "0")
    local short_desc=$(get_json_value "$product" "shortDesc" "")
    
    local vat_included=$(get_json_value "$site_data" "vatIncluded" "(VAT Included)")
    local add_to_basket=$(get_json_value "$site_data" "addToBasket" "Add to Basket")
    
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

generate_products_list() {
    local products_data="$1"
    local site_data="$2"
    local limit="${3:-4}"
    local is_linked="${4:-true}"
    
    echo "    <ul id=\"products\">"
    
    if echo "$products_data" | jq -e '.products | type == "array"' > /dev/null 2>&1; then
        local count=0
        while IFS= read -r product && [ $count -lt $limit ]; do
            if [ -n "$product" ]; then
                local decoded=$(echo "$product" | base64 -d 2>/dev/null || echo '{}')
                if [ -n "$decoded" ] && [ "$decoded" != "{}" ]; then
                    generate_product_card "$decoded" "$site_data" "$is_linked"
                    ((count++))
                fi
            fi
        done < <(get_json_array "$products_data" "products")
    fi
    
    echo "    </ul>"
}

generate_product_detail_content() {
    local product="$1"
    local site_data="$2"
    
    local id=$(get_json_value "$product" "id" "")
    local name=$(get_json_value "$product" "name" "")
    local url=$(get_json_value "$product" "url" "")
    local price=$(get_json_value "$product" "price" "0")
    
    local vat_included=$(get_json_value "$site_data" "vatIncluded" "(VAT Included)")
    local add_to_basket=$(get_json_value "$site_data" "addToBasket" "Add to Basket")
    
    local long_desc_html=""
    if echo "$product" | jq -e '.longDesc | type == "array"' > /dev/null 2>&1; then
        local combined_desc=""
        while IFS= read -r desc_line; do
            if [ -n "$desc_line" ]; then
                desc_line=$(echo "$desc_line" | tr -d '\000-\037' | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [ -n "$combined_desc" ]; then
                    combined_desc="${combined_desc} $desc_line"
                else
                    combined_desc="$desc_line"
                fi
            fi
        done < <(get_json_array "$product" "longDesc")
        
        if [ -n "$combined_desc" ]; then
            long_desc_html="            <p class=\"centered-paragraph\">$combined_desc</p>"
        fi
    fi
    
    cat << EOF
    <article class="prd">
        <li data-id="$id">
            <img src="/static/img/products/$url.jpg" alt="$name" data-url="$url" />
            <h2 data-url="$url">$name</h2>
            <strong>$price TL <em>$vat_included</em></strong>
            <button class="btnAddToBasket" onclick="fnAddToBasket.call(this)">$add_to_basket</button>
            <br/>
        </li>
$long_desc_html    </article>
EOF
}

export -f generate_product_card generate_products_list generate_product_detail_content
