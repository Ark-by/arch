#!/usr/bin/env bash
# wallhaven-list.sh — список одной страницы Wallhaven для UI (без скачивания обоев).
#
#   wallhaven-list.sh <page> <url> [apikey]
#
# Печатает по одной JSON-строке на каждые обои и последней строкой — meta:
#   {"id","resolution","path","thumb","size"}
#   {"meta":{"page":N,"lastPage":N,"total":N}}
#
# Ссылку можно давать как с сайта (wallhaven.cc/toplist, /hot, /search?q=..., 
# /collections/<user>/<id>), так и сразу api/v1.
set -Eeuo pipefail

page="${1:-1}"
src="${2:-https://wallhaven.cc/api/v1/search?sorting=toplist}"
key="${3:-${WALLHAVEN_KEY:-}}"

die() { echo "wallhaven-list: $*" >&2; exit 1; }

[[ "$page" =~ ^[0-9]+$ ]] || die "страница должна быть числом: $page"
command -v curl >/dev/null 2>&1 || die "нужен curl (pacman -S curl)"
command -v jq   >/dev/null 2>&1 || die "нужен jq (pacman -S jq)"

# Ссылку с сайта превращаем в API-URL: работаем только с api/v1.
normalize_api() {
    local u="$1"
    if [[ "$u" == *"/api/v1/"* ]]; then
        printf '%s' "$u"
        return 0
    fi
    case "$u" in
        */hot|*/hot/)          u="https://wallhaven.cc/api/v1/search?sorting=hot" ;;
        */toplist|*/toplist/)  u="https://wallhaven.cc/api/v1/search?sorting=toplist" ;;
        */random|*/random/)    u="https://wallhaven.cc/api/v1/search?sorting=random" ;;
        */latest|*/latest/)    u="https://wallhaven.cc/api/v1/search?sorting=date_added" ;;
        */search*)             u="${u/wallhaven.cc\/search/wallhaven.cc\/api\/v1\/search}" ;;
        */collections/*)       u="${u/wallhaven.cc\/collections/wallhaven.cc\/api\/v1\/collections}" ;;
    esac
    printf '%s' "$u"
}

api="$(normalize_api "$src")"
[[ "$api" == *"/api/v1/"* ]] || die "не похоже на Wallhaven: $src"

sep='?'
[[ "$api" == *\?* ]] && sep='&'
url="${api}${sep}page=${page}"
[[ -n "$key" ]] && url="${url}&apikey=${key}"

resp="$(curl -sS --max-time 25 --retry 2 -H 'User-Agent: quickshell-ark' -w $'\n%{http_code}' "$url")" \
    || die "сеть недоступна"

body="${resp%$'\n'*}"
code="${resp##*$'\n'}"

case "$code" in
    200)          ;;
    401|403)      die "API-ключ отклонён ($code)" ;;
    429)          die "слишком много запросов, подожди минуту (429)" ;;
    404)          die "не найдено: $src" ;;
    *)            die "HTTP $code" ;;
esac

printf '%s' "$body" | jq -e '.data' >/dev/null 2>&1 || die "ответ не похож на Wallhaven API"

printf '%s' "$body" | jq -c '.data[] | {
    id: .id,
    resolution: .resolution,
    path: .path,
    thumb: .thumbs.large,
    size: .file_size
}'

printf '%s' "$body" | jq -c '{meta: {
    page: .meta.current_page,
    lastPage: .meta.last_page,
    total: .meta.total
}}'
