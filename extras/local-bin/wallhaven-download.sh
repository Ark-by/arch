#!/usr/bin/env bash
# Download one SFW Wallhaven search-results page into ~/Pictures/Wallpapers.
# Compatible with config/quickshell/WallpaperPicker.qml (expects page number as $1).
set -Eeuo pipefail

readonly PAGE="${1:-}"
readonly OUT_DIR="${HOME:?HOME is not set}/Pictures/Wallpapers"
readonly API_URL="https://wallhaven.cc/api/v1/search"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fail() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

if [[ ! "$PAGE" =~ ^[1-9][0-9]*$ ]]; then
    fail "Usage: $0 PAGE_NUMBER (positive integer)"
fi

for command_name in wget jq; do
    command -v "$command_name" >/dev/null 2>&1 || fail "Required command not found: $command_name (install it with pacman)."
done

mkdir -p -- "$OUT_DIR"
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf -- "$TMP_DIR"; }
trap cleanup EXIT

API_JSON="$TMP_DIR/results.json"
URL="${API_URL}?categories=111&purity=100&sorting=date_added&order=desc&page=${PAGE}"

info "Requesting Wallhaven page ${PAGE} (SFW only)..."
if ! wget --quiet --timeout=30 --tries=2 --https-only -O "$API_JSON" "$URL"; then
    fail "Could not contact Wallhaven API. Check your Internet connection and try again."
fi

if ! jq -e '.data | type == "array"' "$API_JSON" >/dev/null 2>&1; then
    API_ERROR="$(jq -r '.error // .message // "Unexpected API response"' "$API_JSON" 2>/dev/null || printf 'Invalid JSON response')"
    fail "Wallhaven API returned an error: ${API_ERROR}"
fi

TOTAL_PAGES="$(jq -r '.meta.totalPages // 0' "$API_JSON")"
ITEMS="$(jq -r '.data | length' "$API_JSON")"

if [[ "$ITEMS" -eq 0 ]]; then
    fail "No wallpapers were returned for page ${PAGE}. Total pages reported: ${TOTAL_PAGES}."
fi

if [[ "$TOTAL_PAGES" =~ ^[0-9]+$ ]] && (( PAGE > TOTAL_PAGES )); then
    fail "Page ${PAGE} is out of range. Wallhaven reports ${TOTAL_PAGES} pages."
fi

DOWNLOADED=0
SKIPPED=0
FAILED=0

while IFS=$'\t' read -r wallpaper_id image_url; do
    [[ -n "$wallpaper_id" && -n "$image_url" ]] || continue

    # Accept only direct image URLs served by Wallhaven's image CDN.
    if [[ "$image_url" != https://w.wallhaven.cc/* ]]; then
        warn "Skipping unexpected image URL for ID ${wallpaper_id}."
        ((FAILED+=1))
        continue
    fi

    filename="${image_url##*/}"
    filename="${filename%%\?*}"
    if [[ ! "$filename" =~ ^wallhaven-[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$ ]]; then
        warn "Skipping unexpected filename: ${filename}"
        ((FAILED+=1))
        continue
    fi

    destination="$OUT_DIR/$filename"
    if [[ -s "$destination" ]]; then
        info "Already exists, skipped: $filename"
        ((SKIPPED+=1))
        continue
    fi

    partial="$destination.part"
    rm -f -- "$partial"
    if wget --quiet --show-progress --timeout=60 --tries=2 --https-only \
        -O "$partial" "$image_url"; then
        if [[ -s "$partial" ]]; then
            mv -- "$partial" "$destination"
            info "Saved: $destination"
            ((DOWNLOADED+=1))
        else
            rm -f -- "$partial"
            warn "Downloaded file was empty: $filename"
            ((FAILED+=1))
        fi
    else
        rm -f -- "$partial"
        warn "Download failed: $filename"
        ((FAILED+=1))
    fi
done < <(jq -r '.data[] | [.id, .path] | @tsv' "$API_JSON")

printf '\nWallhaven page %s finished. Downloaded: %s; already present: %s; failed: %s.\n' \
    "$PAGE" "$DOWNLOADED" "$SKIPPED" "$FAILED"
printf 'Wallpaper directory: %s\n' "$OUT_DIR"

if (( DOWNLOADED == 0 && SKIPPED == 0 )); then
    exit 1
fi
if (( FAILED > 0 )); then
    exit 1
fi
