#!/usr/bin/env bash
# =============================================================================
#  install.sh v2 — восстановление окружения Ark-by после переустановки Arch
#
#  Что делает:
#    1. ставит пакеты из packages.txt и AUR-пакеты из aur.txt;
#    2. восстанавливает config/ -> ~/.config (с бэкапом существующего);
#    3. чинит симлинки внутри конфигов (BatteryWidget, обои);
#    4. восстанавливает внешние компоненты из extras/ (MouseBattery,
#       wallhaven, udev-правила, shell-настройки);
#    5. включает Ly как менеджер входа (ly@tty2 + getty@tty2), с проверкой
#       конфликтующих DM и откатом при частичном успехе;
#    6. печатает итоговый отчёт: сделано / пропущено / требует рук.
#
#  Запуск: из корня репозитория, обычным пользователем (не root).
#    ./install.sh --dry-run     # посмотреть план, ничего не меняя
#    ./install.sh               # выполнить с подтверждениями
#    ./install.sh --yes         # без подтверждений (осторожно)
#
#  Требует рядом с собой: packages.txt, aur.txt, config/
#  Опционально: extras/ — см. описание в restore_extras()
# =============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"
AUR_FILE="$SCRIPT_DIR/aur.txt"
CONFIG_SOURCE="$SCRIPT_DIR/config"
EXTRAS_DIR="$SCRIPT_DIR/extras"

DO_PACKAGES=1
DO_AUR=1
DO_CONFIG=1
DO_LY=1
DRY_RUN=0
ASSUME_YES=0

BACKUP_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/arch-dotfiles-backups"
BACKUP_DIR=""
BUILD_DIR=""

REPORT_OK=()
REPORT_WARN=()
REPORT_MANUAL=()

# ── вывод ────────────────────────────────────────────────────────────────────
info()    { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
error()   { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }
die()     { error "$*"; exit 1; }

ok()     { REPORT_OK+=("$*");     success "$*"; }
warned() { REPORT_WARN+=("$*");   warn "$*"; }
manual() { REPORT_MANUAL+=("$*"); warn "ТРЕБУЕТ РУК: $*"; }

section() {
    printf '\n\033[1m── %s ─────────────────────────────────────\033[0m\n' "$*"
}

confirm() {
    local prompt="$1"
    (( ASSUME_YES )) && return 0
    [[ -t 0 ]] || return 0
    local reply
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

usage() {
    cat <<'USAGE'
Использование: ./install.sh [опции]

  --dry-run        показать план, ничего не изменяя
  --yes            не задавать вопросов (опасно: включает Ly без спроса)
  --no-packages    не ставить пакеты из packages.txt
  --no-aur         не ставить AUR-пакеты из aur.txt
  --no-config      не восстанавливать config/ в ~/.config
  --no-ly          не включать Ly
  -h, --help       эта справка

Скрипт запускается обычным пользователем, не через sudo.
Существующие ~/.config/<name> переносятся в бэкап, а не удаляются.
USAGE
}

while (($#)); do
    case "$1" in
        --dry-run)     DRY_RUN=1 ;;
        --yes)         ASSUME_YES=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-aur)      DO_AUR=0 ;;
        --no-config)   DO_CONFIG=0 ;;
        --no-ly)       DO_LY=0 ;;
        -h|--help)     usage; exit 0 ;;
        *)             die "Неизвестная опция: $1 (см. --help)" ;;
    esac
    shift
done

cleanup() { [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]] && rm -rf "$BUILD_DIR" || true; }
trap cleanup EXIT

# ── проверки окружения ───────────────────────────────────────────────────────
[[ "$EUID" -ne 0 ]] || die "Не запускайте скрипт через sudo. Нужен обычный пользователь."
[[ -f "$PACKAGES_FILE" ]] || die "Не найден packages.txt рядом со скриптом ($SCRIPT_DIR)"
[[ -f "$AUR_FILE" ]]      || die "Не найден aur.txt рядом со скриптом ($SCRIPT_DIR)"
[[ -d "$CONFIG_SOURCE" ]] || die "Не найдена папка config/ рядом со скриптом ($SCRIPT_DIR)"

[[ -r /etc/os-release ]] || die "Нет /etc/os-release — не могу определить систему."
# shellcheck disable=SC1091
. /etc/os-release
if [[ "${ID:-}" != "arch" && " ${ID_LIKE:-} " != *" arch "* ]]; then
    die "Скрипт для Arch или Arch-подобных. Обнаружено: ${PRETTY_NAME:-unknown}"
fi

command -v pacman >/dev/null 2>&1 || die "pacman не найден."

# ── списки пакетов ───────────────────────────────────────────────────────────
read_list() {
    local file="$1" line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -n "$line" ]] && printf '%s\n' "$line"
    done < "$file"
}

mapfile -t PKG_LIST     < <(read_list "$PACKAGES_FILE")
mapfile -t AUR_LIST_RAW < <(read_list "$AUR_FILE")

declare -A IS_AUR=()
for p in "${AUR_LIST_RAW[@]}"; do IS_AUR["$p"]=1; done

NATIVE_REQUESTED=()
for p in "${PKG_LIST[@]}"; do
    [[ -n "${IS_AUR[$p]+x}" ]] && continue
    if [[ "$p" == "amd-ucode" ]] && ! grep -q 'vendor_id.*AuthenticAMD' /proc/cpuinfo 2>/dev/null; then
        warned "amd-ucode пропущен: процессор не AMD."
        continue
    fi
    NATIVE_REQUESTED+=("$p")
done

# Используются в keybinds.lua: brightnessctl и playerctl.
NATIVE_REQUESTED+=(brightnessctl playerctl)

AUR_TO_INSTALL=()
for p in "${AUR_LIST_RAW[@]}"; do
    case "$p" in
        yay)      ;;                       # AUR-хелпер ставится отдельно
        *-debug)  warned "Пропущен отладочный пакет: $p" ;;
        *)        AUR_TO_INSTALL+=("$p") ;;
    esac
done

# ── заголовок ────────────────────────────────────────────────────────────────
section "План"
info "Репозиторий:  $SCRIPT_DIR"
info "Пользователь: $USER (домашний каталог: $HOME)"
info "Пакетов из репозиториев: ${#NATIVE_REQUESTED[@]}"
(( DO_AUR ))    && info "AUR-пакетов: ${#AUR_TO_INSTALL[@]}"
(( DO_CONFIG )) && info "Конфиги: $CONFIG_SOURCE -> $HOME/.config"
(( DO_LY ))     && info "Менеджер входа: Ly на tty2"
[[ -d "$EXTRAS_DIR" ]] && info "Доп. компоненты: $EXTRAS_DIR" || info "Доп. компоненты: extras/ отсутствует"

if (( DRY_RUN )); then
    section "Пакеты из репозиториев"
    printf '  %s\n' "${NATIVE_REQUESTED[@]}"
    if (( DO_AUR )) && ((${#AUR_TO_INSTALL[@]})); then
        section "AUR-пакеты"
        printf '  %s\n' "${AUR_TO_INSTALL[@]}"
    fi
    if (( DO_CONFIG )); then
        section "Конфиги к восстановлению"
        find "$CONFIG_SOURCE" -mindepth 1 -maxdepth 1 -printf '  %f\n' | sort
    fi
    if [[ -d "$EXTRAS_DIR" ]]; then
        section "Доп. компоненты"
        find "$EXTRAS_DIR" -mindepth 1 -maxdepth 2 -printf '  %P\n' | sort | head -40
    fi
    printf '\n'
    info "Режим --dry-run: изменений не внесено."
    exit 0
fi

confirm "Продолжить?" || { info "Отменено."; exit 0; }

SUDO="sudo"
command -v sudo >/dev/null 2>&1 || die "Нужен sudo."
$SUDO -v || die "Не удалось получить права sudo."

# =============================================================================
# 1. Пакеты из официальных репозиториев
# =============================================================================
if (( DO_PACKAGES )); then
    section "Пакеты из репозиториев"

    info "pacman -Syu ..."
    $SUDO pacman -Syu || warned "pacman -Syu завершился с ошибкой, продолжаю."

    declare -A IN_REPO=()
    while IFS= read -r p; do IN_REPO["$p"]=1; done < <(pacman -Slq | sort -u)

    NATIVE_AVAILABLE=()
    for p in "${NATIVE_REQUESTED[@]}"; do
        if [[ -n "${IN_REPO[$p]+x}" ]]; then
            NATIVE_AVAILABLE+=("$p")
        else
            warned "Нет в репозиториях, пропущено: $p"
        fi
    done

    if ((${#NATIVE_AVAILABLE[@]})); then
        info "Устанавливаю ${#NATIVE_AVAILABLE[@]} пакетов..."
        if $SUDO pacman -S --needed --noconfirm "${NATIVE_AVAILABLE[@]}"; then
            ok "Пакеты из репозиториев установлены."
        else
            manual "Часть пакетов не установилась. Повторите: sudo pacman -S --needed ${NATIVE_AVAILABLE[*]}"
        fi
    else
        warned "Ни один пакет не найден в репозиториях."
    fi
fi

# =============================================================================
# 2. AUR
# =============================================================================
if (( DO_AUR )) && ((${#AUR_TO_INSTALL[@]})); then
    section "AUR-пакеты"

    AUR_HELPER=""
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        info "AUR-хелпер не найден, собираю yay из AUR..."
        $SUDO pacman -S --needed --noconfirm base-devel git || die "Не удалось поставить base-devel/git."
        BUILD_DIR="$(mktemp -d -t yay-build.XXXXXX)"
        git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay" || die "Не удалось склонировать yay."
        ( cd "$BUILD_DIR/yay" && makepkg -si --noconfirm ) || die "Сборка yay не удалась."
        command -v yay >/dev/null 2>&1 || die "yay не установился."
        AUR_HELPER="yay"
        ok "yay установлен."
    fi

    AUR_FAILED=()
    for p in "${AUR_TO_INSTALL[@]}"; do
        info "AUR: $p"
        if "$AUR_HELPER" -S --needed --noconfirm "$p"; then
            :
        else
            AUR_FAILED+=("$p")
        fi
    done

    if ((${#AUR_FAILED[@]})); then
        manual "Не установились AUR-пакеты: ${AUR_FAILED[*]}"
    else
        ok "AUR-пакеты установлены (${#AUR_TO_INSTALL[@]})."
    fi
fi

# =============================================================================
# 3. Конфиги: config/ -> ~/.config
# =============================================================================
ensure_backup_dir() {
    if [[ -z "$BACKUP_DIR" ]]; then
        BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
    fi
}

if (( DO_CONFIG )); then
    section "Конфиги"

    mkdir -p "$HOME/.config"
    mapfile -d '' CONFIG_ENTRIES < <(find "$CONFIG_SOURCE" -mindepth 1 -maxdepth 1 -print0)

    for src in "${CONFIG_ENTRIES[@]}"; do
        name="$(basename "$src")"
        dst="$HOME/.config/$name"

        if [[ -e "$dst" || -L "$dst" ]]; then
            ensure_backup_dir
            mv -- "$dst" "$BACKUP_DIR/$name"
            info "  ~/.config/$name -> бэкап"
        fi

        cp -a -- "$src" "$dst"
        ok "Восстановлен ~/.config/$name"
    done

    # --- BatteryWidget.qml: в репозитории это симлинк на отдельный проект ---
    BW="$HOME/.config/quickshell/BatteryWidget.qml"
    MB_DIR="$HOME/Programs/MouseBattery"
    MB_QML=""
    for candidate in \
        "$MB_DIR/quickshell/BatteryWidget.qml" \
        "$MB_DIR/BatteryWidget.qml"; do
        [[ -f "$candidate" ]] && { MB_QML="$candidate"; break; }
    done

    needs_bw=0
    if [[ -L "$BW" && ! -e "$BW" ]]; then
        needs_bw=1
    elif [[ -f "$BW" && ! -L "$BW" ]] && head -n1 "$BW" 2>/dev/null | grep -q '^/home/.*MouseBattery'; then
        needs_bw=1
    fi

    if (( needs_bw )); then
        if [[ -n "$MB_QML" ]]; then
            cp -f -- "$MB_QML" "$BW"
            ok "BatteryWidget.qml восстановлен из $MB_QML"
        else
            cat > "$BW" <<'QML'
import QtQuick

// Заглушка: полный проект MouseBattery хранится отдельно от репозитория.
Item {
    property color panelBackground: "transparent"
    property color panelForeground: "white"
    property color panelSurface: "transparent"
    property color panelAccent: "white"
    implicitWidth: 0
    implicitHeight: 0
}
QML
            manual "BatteryWidget.qml — вставлена заглушка. Нужен проект ~/Programs/MouseBattery (виджет батареи мыши)."
        fi
    fi

    # --- обои: путь мог остаться от старой установки ---
    WALLPAPER_FILE="$HOME/.config/quickshell/wallpaper.txt"
    if [[ -f "$WALLPAPER_FILE" ]]; then
        SAVED="$(tr -d '\r\n' < "$WALLPAPER_FILE")"
        if [[ -n "$SAVED" && ! -f "$SAVED" ]]; then
            NEW=""
            if [[ -d "$HOME/Pictures" ]]; then
                NEW="$(find "$HOME/Pictures" -type f \
                    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
                    -print -quit 2>/dev/null || true)"
            fi
            printf '%s' "$NEW" > "$WALLPAPER_FILE"
            if [[ -n "$NEW" ]]; then
                warned "Старые обои не найдены, выбраны: $NEW"
            else
                manual "Обои не найдены. Выберите новые через Quickshell (Super+W)."
            fi
        fi
    fi
fi

# =============================================================================
# 4. Внешние компоненты из extras/
# =============================================================================
#  extras/ — необязательная папка в репозитории, куда кладутся вещи,
#  которые раньше жили вне git:
#
#    extras/Programs/MouseBattery/          -> ~/Programs/MouseBattery
#    extras/.local/bin/wallhaven-download.sh -> ~/.local/bin/
#    extras/udev/*.rules                     -> /etc/udev/rules.d/ (sudo)
#    extras/home/.zshrc                      -> ~/.zshrc
#    extras/home/.config/...                 -> ~/.config/...
#
#  Чего нет в extras/, скрипт не выдумывает — он пишет это в отчёт.
restore_extras() {
    [[ -d "$EXTRAS_DIR" ]] || { warned "Папки extras/ нет — внешние компоненты не восстановлены."; return 0; }

    # 4.1 Проект MouseBattery
    if [[ -d "$EXTRAS_DIR/Programs/MouseBattery" ]]; then
        mkdir -p "$HOME/Programs"
        if [[ -e "$HOME/Programs/MouseBattery" ]]; then
            ensure_backup_dir
            mv -- "$HOME/Programs/MouseBattery" "$BACKUP_DIR/Programs-MouseBattery"
        fi
        cp -a -- "$EXTRAS_DIR/Programs/MouseBattery" "$HOME/Programs/MouseBattery"
        ok "MouseBattery восстановлен."
    else
        manual "extras/Programs/MouseBattery отсутствует — виджет батареи останется заглушкой."
    fi

    # 4.2 wallhaven-download.sh
    if [[ -f "$EXTRAS_DIR/.local/bin/wallhaven-download.sh" ]]; then
        mkdir -p "$HOME/.local/bin"
        cp -a -- "$EXTRAS_DIR/.local/bin/wallhaven-download.sh" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/wallhaven-download.sh"
        ok "wallhaven-download.sh восстановлен."
    else
        manual "extras/.local/bin/wallhaven-download.sh отсутствует — скачивание обоев не заработает."
    fi

    # 4.3 udev-правила (ARDOR Phantom PRO и прочее)
    if compgen -G "$EXTRAS_DIR/udev/*.rules" > /dev/null; then
        for rule in "$EXTRAS_DIR"/udev/*.rules; do
            $SUDO install -m 644 "$rule" /etc/udev/rules.d/
            ok "udev-правило установлено: $(basename "$rule")"
        done
        $SUDO udevadm control --reload-rules && $SUDO udevadm trigger || \
            warned "udevadm не отработал, правила применятся после перезагрузки."
    else
        manual "extras/udev/*.rules отсутствует — udev-правила для ARDOR не установлены."
    fi

    # 4.4 Пользовательские файлы (shell-настройки и прочее)
    if [[ -d "$EXTRAS_DIR/home" ]]; then
        mapfile -d '' HOME_ITEMS < <(find "$EXTRAS_DIR/home" -mindepth 1 -maxdepth 1 -print0)
        for item in "${HOME_ITEMS[@]}"; do
            base="$(basename "$item")"
            target="$HOME/$base"
            if [[ -e "$target" || -L "$target" ]]; then
                ensure_backup_dir
                mv -- "$target" "$BACKUP_DIR/home-$base"
            fi
            cp -a -- "$item" "$target"
            ok "Восстановлен ~/$base"
        done
    else
        manual "extras/home отсутствует — ~/.zshrc, ~/.bashrc и прочие файлы вне репозитория не восстановлены."
    fi
}

section "Внешние компоненты"
restore_extras

# =============================================================================
# 5. Менеджер входа: Ly
# =============================================================================
#  Ly 1.4 в Arch поставляется как ly@.service (шаблон), отдельного ly.service нет.
#  Порядок: включить ly@tty2, затем отключить getty@tty2.
#  Совместимость: если включён другой DM, Ly не трогаем.
enable_ly() {
    command -v systemctl >/dev/null 2>&1 || { manual "systemctl не найден — Ly не настроен."; return 0; }
    pacman -Q ly >/dev/null 2>&1 || { manual "Пакет ly не установлен — менеджер входа не настроен."; return 0; }

    local dm_conflict=""
    [[ -e /etc/systemd/system/display-manager.service ]] && dm_conflict="display-manager.service"
    systemctl is-active --quiet display-manager.service 2>/dev/null && \
        dm_conflict="${dm_conflict:+$dm_conflict, }активный DM"

    if [[ -n "$dm_conflict" ]]; then
        manual "Уже настроен другой менеджер входа ($dm_conflict). Отключите его и включите Ly вручную:
    sudo systemctl enable ly@tty2.service
    sudo systemctl disable getty@tty2.service"
        return 0
    fi

    if ! confirm "Включить Ly как экран входа на tty2?"; then
        warned "Ly установлен, но не включён."
        return 0
    fi

    if ! $SUDO systemctl enable ly@tty2.service; then
        manual "Не удалось включить ly@tty2.service."
        return 0
    fi

    if $SUDO systemctl disable getty@tty2.service; then
        ok "Ly включён на tty2, getty@tty2 отключён."
    else
        $SUDO systemctl disable ly@tty2.service || true
        manual "getty@tty2 не отключился — включение Ly отменено. Включите вручную:
    sudo systemctl enable ly@tty2.service
    sudo systemctl disable getty@tty2.service"
    fi
}

if (( DO_LY )); then
    section "Менеджер входа (Ly)"
    enable_ly
fi

# =============================================================================
# 6. Проверка окружения
# =============================================================================
section "Проверка окружения"

check_cmd() {
    local c="$1" hint="${2:-}"
    if command -v "$c" >/dev/null 2>&1; then
        ok "команда найдена: $c"
    else
        if [[ -n "$hint" ]]; then
            manual "команда не найдена: $c ($hint)"
        else
            warned "команда не найдена: $c"
        fi
    fi
}

check_cmd hyprland "пакет hyprland"
check_cmd qs        "пакет quickshell (меню панели: Super+R/W/T/Z/I/A)"
check_cmd subl      "пакет sublime-text-4 (Super+S)"
check_cmd brightnessctl "клавиши яркости"
check_cmd playerctl "мультимедиа-клавиши"
check_cmd uwsm      "сессия Hyprland через UWSM"

if command -v hyprland >/dev/null 2>&1; then
    hv="$(hyprland --version 2>/dev/null | head -n1 || true)"
    [[ -n "$hv" ]] && info "Hyprland: $hv"
    info "Ваш конфиг — hyprland.lua; проверьте, что версия Hyprland поддерживает Lua-конфиг."
fi

# Сохраняем фактические списки пакетов отдельными файлами (не перезаписывая
# курируемые packages.txt/aur.txt).
pacman -Qqe > "$SCRIPT_DIR/packages-current.txt" 2>/dev/null && \
    info "Фактический список пакетов: packages-current.txt"
pacman -Qqm > "$SCRIPT_DIR/foreign-current.txt" 2>/dev/null && \
    info "Пакеты не из репозиториев: foreign-current.txt (сверьте с aur.txt вручную)"

# =============================================================================
# 7. Итоговый отчёт
# =============================================================================
section "Итог"

printf '\n\033[1;32mСделано: %d\033[0m\n' "${#REPORT_OK[@]}"
((${#REPORT_OK[@]}))     && printf '  • %s\n' "${REPORT_OK[@]}"

printf '\n\033[1;33mПредупреждения: %d\033[0m\n' "${#REPORT_WARN[@]}"
((${#REPORT_WARN[@]}))   && printf '  • %s\n' "${REPORT_WARN[@]}"

printf '\n\033[1;31mТребует рук: %d\033[0m\n' "${#REPORT_MANUAL[@]}"
((${#REPORT_MANUAL[@]})) && printf '  • %s\n' "${REPORT_MANUAL[@]}"

[[ -n "$BACKUP_DIR" ]] && printf '\n\033[1mБэкап прежних конфигов:\033[0m %s\n' "$BACKUP_DIR"

cat <<'NEXT'

Дальше:
  1. Перезагрузитесь.
  2. На экране Ly выберите сессию Hyprland и войдите.
  3. Панель запускается автоматически; вручную — qs
  4. Обои: Super+W. Темы: Super+T. Справка по клавишам: Super+A.

Если Ly не запустится — переключитесь на Ctrl+Alt+F3 (или F6):
там остаётся резервная консоль входа, tty2 отдан Ly.

Если Hyprland не стартует из Ly, есть альтернатива: отказаться от DM
и запускать сессию из tty1 через ~/.zprofile:

    if [[ -z "${WAYLAND_DISPLAY:-}" && "$(tty 2>/dev/null)" == "/dev/tty1" ]] &&
       uwsm check may-start >/dev/null 2>&1; then
        exec uwsm start hyprland.desktop
    fi

UFW установлен из списка пакетов, но НЕ включён: sudo ufw enable
NEXT
