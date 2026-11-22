#!/usr/bin/env bash
set -Eeuo pipefail

API="https://wallhaven.cc/api/v1/collections/lewdpatriot/935888"
DEST="$HOME/Pictures/Wallpapers"
DEFAULT_PAGE=14

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
echo "Получаю страницу $page из Wallhaven..."

# Запрашиваем только выбранную страницу
response="$(curl -fsSL --retry 2 "${API}?page=${page}")" || {
    echo "Не удалось получить данные Wallhaven."
    exit 1
}

last_page="$(jq -r '.meta.last_page // empty' <<< "$response")"
current_page="$(jq -r '.meta.current_page // empty' <<< "$response")"

if [[ -z "$last_page" || -z "$current_page" ]]; then
    echo "Не удалось прочитать ответ API."
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
