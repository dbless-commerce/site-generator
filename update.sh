#!/usr/bin/env bash
#
# update.sh - Incremental site update script
#
# Detects changes in site data and regenerates only affected sites.
#
# Usage:
#   ./update.sh          # Auto-detect and update changed sites
#   ./update.sh en       # Force update English site only
#   ./update.sh ar tr    # Force update Arabic and Turkish sites
#   ./update.sh --all    # Regenerate all sites (same as generate-all.sh)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils/utils.sh"

set_error_handling

# Track which languages need updating
LANGS_TO_UPDATE=()

# Check if shared files (CSS, JS, images) have changed
SHARED_CHANGED=false

detect_changes() {
    log "Detecting changes..."

    # Check shared files for changes (affects all sites)
    local shared_dirs=("files/css" "files/js" "files/img")
    for dir in "${shared_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local changed=$(find "$dir" -newer ".last_build" -type f 2>/dev/null | head -1)
            if [ -n "$changed" ]; then
                SHARED_CHANGED=true
                info "Shared files changed in $dir"
                break
            fi
        fi
    done

    # Check each language site for data changes
    for lang in "${LANGUAGES[@]}"; do
        local data_dir="./site-${lang}/data"
        if [ -d "$data_dir" ]; then
            if [ ! -f ".last_build" ]; then
                # No previous build marker, update everything
                LANGS_TO_UPDATE+=("$lang")
                debug "No previous build found, will update $lang"
            else
                local changed=$(find "$data_dir" -newer ".last_build" -type f 2>/dev/null | head -1)
                if [ -n "$changed" ]; then
                    LANGS_TO_UPDATE+=("$lang")
                    info "Data changed for site-$lang"
                fi
            fi
        fi
    done

    # If shared files changed, update all languages
    if [ "$SHARED_CHANGED" = true ]; then
        LANGS_TO_UPDATE=()
        for lang in "${LANGUAGES[@]}"; do
            if [ -d "./site-${lang}" ]; then
                LANGS_TO_UPDATE+=("$lang")
            fi
        done
        info "Shared files changed - all sites will be updated"
    fi
}

update_site() {
    local lang="$1"

    if [ ! -d "./site-${lang}" ]; then
        warn "Site directory ./site-${lang} not found, skipping..."
        return 1
    fi

    print_section "Updating site-${lang}"

    # Set environment for the language
    export CURRENT_LANG="$lang"
    export DATA_DIR="./site-${lang}/data"
    export OUTPUT_DIR="./site-${lang}"

    # Run page generation for this language
    log "Generating pages for $lang..."
    bash "$SCRIPT_DIR/scripts/tasks/create-pages.sh" "$lang" 2>&1 || true

    # Run product generation
    log "Generating products for $lang..."
    bash "$SCRIPT_DIR/scripts/tasks/create-products.sh" "$lang" 2>&1 || true

    success "Updated site-${lang}"
    return 0
}

update_shared() {
    if [ "$SHARED_CHANGED" = true ] || [ "$FORCE_ALL" = true ]; then
        print_section "Updating shared resources"

        log "Bundling CSS..."
        bash "$SCRIPT_DIR/scripts/tasks/create-css.sh" 2>&1 || true

        log "Copying images..."
        bash "$SCRIPT_DIR/scripts/tasks/copy-images.sh" 2>&1 || true

        log "Copying JavaScript..."
        bash "$SCRIPT_DIR/scripts/tasks/create-js.sh" 2>&1 || true

        success "Shared resources updated"
    fi
}

main() {
    start_timer
    print_banner "Site Update Script"

    local FORCE_ALL=false

    # Parse arguments
    if [ $# -gt 0 ]; then
        if [ "$1" = "--all" ]; then
            FORCE_ALL=true
            SHARED_CHANGED=true
            for lang in "${LANGUAGES[@]}"; do
                if [ -d "./site-${lang}" ]; then
                    LANGS_TO_UPDATE+=("$lang")
                fi
            done
            info "Force updating all sites"
        else
            # Specific languages provided
            SHARED_CHANGED=true
            for lang in "$@"; do
                if is_valid_language "$lang"; then
                    LANGS_TO_UPDATE+=("$lang")
                else
                    warn "Invalid language: $lang (valid: ${LANGUAGES[*]})"
                fi
            done
        fi
    else
        # Auto-detect changes
        detect_changes
    fi

    # Check if there's anything to do
    if [ ${#LANGS_TO_UPDATE[@]} -eq 0 ] && [ "$SHARED_CHANGED" = false ]; then
        success "No changes detected. Nothing to update."
        touch ".last_build"
        end_timer "Update check"
        exit 0
    fi

    info "Sites to update: ${LANGS_TO_UPDATE[*]:-none}"
    info "Shared resources: $([ "$SHARED_CHANGED" = true ] && echo "will update" || echo "no changes")"

    # Update shared resources (CSS, JS, images)
    update_shared

    # Update each changed language site
    local updated_sites=()
    local failed_sites=()

    for lang in "${LANGS_TO_UPDATE[@]}"; do
        if update_site "$lang"; then
            updated_sites+=("$lang")
        else
            failed_sites+=("$lang")
        fi
    done

    # Update the build timestamp marker
    touch ".last_build"

    # Summary
    echo ""
    if [ ${#updated_sites[@]} -gt 0 ]; then
        print_summary "Updated Sites" "${updated_sites[@]}"
    fi

    if [ ${#failed_sites[@]} -gt 0 ]; then
        warn "Failed sites: ${failed_sites[*]}"
    fi

    end_timer "Site update"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
