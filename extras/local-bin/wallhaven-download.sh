#!/usr/bin/env bash
set -Eeuo pipefail

DEFAULT_API="https://wallhaven.cc/api/v1/collections/lewdpatriot/935888"
# Источник: 2-й аргумент, затем переменная окружения, затем значение по умолчанию
API="${2:-${WALLHAVEN_API:-$DEFAULT_API}}"
KEY="${3:-${WALLHAVEN_KEY:-}}"
if [[ -n "$KEY" ]]; then
    echo "API key: задан"
else
    echo "API key: нет (только SFW)"
fi
DEST="${WALLHAVEN_DEST:-$HOME/Pictures/Wallpapers}"
DEFAULT_PAGE=14

# Ссылку с сайта (wallhaven.cc/hot, /toplist, /search?q=..., /collections/...)
# превращаем в API-URL: скрипт работает только с api/v1.
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

API="$(normalize_api "$API")"

if [[ "$API" != *"/api/v1/"* ]]; then
    echo "Не похоже на Wallhaven API: $API"
    echo
    echo "Подойдут ссылки:"
    echo "  https://wallhaven.cc/hot"
    echo "  https://wallhaven.cc/toplist"
    echo "  https://wallhaven.cc/search?q=anime"
    echo "  https://wallhaven.cc/collections/<user>/<id>"
    echo "  https://wallhaven.cc/api/v1/search?q=anime   (уже API)"
    exit 1
fi

# Проверка необходимых программ
for cmd in curl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Не найдена программа: $cmd"
        echo "Установи её командой: sudo pacman -S --needed curl jq"
        exit 1
    fi
done

# Выбор страницы
if [[ $# -ge 1 ]]; then
    page="$1"
else
    read -r -p "Номер страницы [${DEFAULT_PAGE}]: " page
    page="${page:-$DEFAULT_PAGE}"
fi

if [[ ! "$page" =~ ^[1-9][0-9]*$ ]]; then
    echo "Ошибка: введи положительный номер страницы."
    exit 1
fi

echo
echo "Источник: $API"
echo "Получаю страницу $page..."

# Запрашиваем только выбранную страницу
sep="?"
[[ "$API" == *\?* ]] && sep="&"
url="${API}${sep}page=${page}"
if [[ -n "$KEY" && "$url" != *"apikey="* ]]; then
    url="${url}&apikey=${KEY}"
fi
response="$(curl -fsSL --retry 2 "$url")" || {
    echo "Не удалось получить данные Wallhaven."
    exit 1
}

last_page="$(jq -r '.meta.last_page // empty' <<< "$response")"
current_page="$(jq -r '.meta.current_page // empty' <<< "$response")"

if [[ -z "$last_page" || -z "$current_page" ]]; then
    echo "Не удалось прочитать ответ API."
    echo "Ответ сервера: $(head -c 300 <<< "$response")"
    exit 1
fi

if (( page > last_page )); then
    echo "Такой страницы нет. Последняя доступная: $last_page."
    exit 1
fi

count="$(jq '.data | length' <<< "$response")"

if (( count == 0 )); then
    echo "На этой странице изображений нет."
    exit 0
fi

mkdir -p "$DEST"

echo "Страница: $current_page из $last_page"
echo "Изображений: $count"
echo "Папка: $DEST"
echo

downloaded=0
skipped=0
failed=0

while IFS=$'\t' read -r id resolution url; do
    filename="${url##*/}"
    filepath="$DEST/$filename"

    if [[ -f "$filepath" ]]; then
        echo "[Уже есть] $filename"
        skipped=$((skipped + 1))
        continue
    fi

    echo "[Загрузка] $id ($resolution)"

    if curl -fLsS --retry 2 --output "$filepath" "$url"; then
        downloaded=$((downloaded + 1))
    else
        echo "[Ошибка] $filename"
        rm -f "$filepath"
        failed=$((failed + 1))
    fi
done < <(jq -r '.data[] | [.id, .resolution, .path] | @tsv' <<< "$response")

echo
echo "Готово!"
echo "Загружено: $downloaded"
echo "Уже существовало: $skipped"
echo "Ошибок: $failed"
