#!/usr/bin/env bash
# =============================================================================
#  install.sh v3 — восстановление окружения Ark-by после переустановки Arch
#
#  Что делает:
#    1. ставит пакеты из packages.txt и AUR-пакеты из aur.txt;
#    2. создаёт XDG-каталоги (~/Documents, ~/Downloads и т. д.);
#    3. восстанавливает config/ -> ~/.config (с бэкапом существующего);
#    4. чинит симлинки внутри конфигов (BatteryWidget, обои);
#    5. разворачивает extras/:
#         extras/local-bin/*            -> ~/.local/bin/         (chmod +x)
#         extras/.zshrc, extras/.bashrc -> ~/
#         extras/.oh-my-zsh/**          -> ~/.oh-my-zsh/         (поверх, не затирая)
#         extras/etc/**                 -> /etc/**               (sudo)
#         extras/Programs/*             -> ~/Programs/
#         extras/udev/*.rules           -> /etc/udev/rules.d/    (sudo, если есть)
#    6. включает Ly как менеджер входа (ly@tty2 + getty@tty2);
#    7. проверяет shell, fastfetch, Firefox policies, команды Hyprland;
#    8. печатает отчёт: сделано / предупреждения / требует рук.
#
#  Запуск: из корня репозитория, обычным пользователем (не root).
#    ./install-v2.sh --dry-run
#    ./install-v2.sh
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
DO_EXTRAS=1
DO_LY=1
DO_RUSTDESK=1
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
Использование: ./install-v2.sh [опции]

  --dry-run        показать план, ничего не изменяя
  --yes            не задавать вопросов (включает Ly без спроса)
  --no-packages    не ставить пакеты из packages.txt
  --no-aur         не ставить AUR-пакеты из aur.txt
  --no-config      не восстанавливать config/ в ~/.config
  --no-extras      не разворачивать extras/
  --no-ly          не включать Ly
  --no-rustdesk    не настраивать RustDesk (uinput, портал)
  -h, --help       эта справка

Запускать обычным пользователем, не через sudo.
Существующие файлы переносятся в бэкап, а не удаляются.
USAGE
}

while (($#)); do
    case "$1" in
        --dry-run)     DRY_RUN=1 ;;
        --yes)         ASSUME_YES=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-aur)      DO_AUR=0 ;;
        --no-config)   DO_CONFIG=0 ;;
        --no-extras)   DO_EXTRAS=0 ;;
        --no-ly)       DO_LY=0 ;;
        --no-rustdesk) DO_RUSTDESK=0 ;;
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

# Нужны конфигам и приложениям, но отсутствовали в packages.txt:
#   brightnessctl, playerctl — keybinds.lua;
#   xdg-user-dirs — ~/Documents, иначе RustDesk ругается на документы;
#   xdg-desktop-portal — фронтенд порталов (rustdesk-bin его НЕ тянет).
NATIVE_REQUESTED+=(brightnessctl playerctl xdg-user-dirs xdg-desktop-portal)

AUR_TO_INSTALL=()
for p in "${AUR_LIST_RAW[@]}"; do
    case "$p" in
        yay)      ;;
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
(( DO_EXTRAS )) && { [[ -d "$EXTRAS_DIR" ]] && info "extras/: найдена" || info "extras/: отсутствует"; }
(( DO_LY ))     && info "Менеджер входа: Ly на tty2"

if (( DRY_RUN )); then
    section "Пакеты из репозиториев"
    printf '  %s\n' "${NATIVE_REQUESTED[@]}"
    if (( DO_AUR )) && ((${#AUR_TO_INSTALL[@]})); then
        section "AUR-пакеты"
        printf '  %s\n' "${AUR_TO_INSTALL[@]}"
    fi
    if (( DO_CONFIG )); then
        section "Конфиги"
        find "$CONFIG_SOURCE" -mindepth 1 -maxdepth 1 -printf '  %f\n' | sort
    fi
    if (( DO_EXTRAS )) && [[ -d "$EXTRAS_DIR" ]]; then
        section "extras/ — что будет развёрнуто"
        find "$EXTRAS_DIR" -mindepth 1 -maxdepth 3 -printf '  %P\n' | sort | head -60
    fi
    printf '\n'
    info "Режим --dry-run: изменений не внесено."
    exit 0
fi

confirm "Продолжить?" || { info "Отменено."; exit 0; }

command -v sudo >/dev/null 2>&1 || die "Нужен sudo."
SUDO="sudo"
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
        if $SUDO pacman -S --needed --noconfirm "${NATIVE_AVAILABLE[@]}"; then
            ok "Пакеты из репозиториев установлены (${#NATIVE_AVAILABLE[@]})."
        else
            manual "Часть пакетов не установилась: sudo pacman -S --needed ${NATIVE_AVAILABLE[*]}"
        fi
    else
        warned "Ни один пакет не найден в репозиториях."
    fi

    # XDG-каталоги: без них часть приложений (например, RustDesk) ругается
    # на отсутствие папки документов.
    if command -v xdg-user-dirs-update >/dev/null 2>&1; then
        if xdg-user-dirs-update; then
            ok "XDG-каталоги созданы (~/Documents, ~/Downloads, ~/Pictures)."
        else
            warned "xdg-user-dirs-update завершился с ошибкой."
        fi
    else
        warned "xdg-user-dirs-update не найден — ~/Documents может отсутствовать."
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
        "$AUR_HELPER" -S --needed --noconfirm "$p" || AUR_FAILED+=("$p")
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
            manual "BatteryWidget.qml — заглушка. Нужен проект ~/Programs/MouseBattery."
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
                manual "Обои не найдены. Выберите через Quickshell (Super+W)."
            fi
        fi
    fi
fi

# =============================================================================
# 4. extras/
# =============================================================================
restore_extras() {
    [[ -d "$EXTRAS_DIR" ]] || { manual "Папки extras/ нет — внешние компоненты не восстановлены."; return 0; }

    # 4.1 ~/.local/bin
    if compgen -G "$EXTRAS_DIR/local-bin/*" > /dev/null; then
        mkdir -p "$HOME/.local/bin"
        local f base
        for f in "$EXTRAS_DIR"/local-bin/*; do
            base="$(basename "$f")"
            cp -a -- "$f" "$HOME/.local/bin/$base"
            chmod +x "$HOME/.local/bin/$base"
            ok "Восстановлен ~/.local/bin/$base"
        done
    else
        manual "extras/local-bin пуст — скрипт скачивания обоев не восстановлен."
    fi

    # 4.2 dotfiles в корне extras/ (.zshrc, .bashrc, .zprofile, ...)
    local item base
    mapfile -d '' EXTRAS_ROOTS < <(find "$EXTRAS_DIR" -mindepth 1 -maxdepth 1 -name '.*' -print0)
    for item in "${EXTRAS_ROOTS[@]}"; do
        base="$(basename "$item")"
        [[ "$base" == ".oh-my-zsh" ]] && continue
        if [[ -e "$HOME/$base" || -L "$HOME/$base" ]]; then
            ensure_backup_dir
            mv -- "$HOME/$base" "$BACKUP_DIR/home-$base"
        fi
        cp -a -- "$item" "$HOME/$base"
        ok "Восстановлен ~/$base"
    done

    # 4.3 oh-my-zsh: тема копируется поверх, фреймворк доставляется при отсутствии
    if [[ -d "$EXTRAS_DIR/.oh-my-zsh" ]]; then
        mkdir -p "$HOME/.oh-my-zsh"
        cp -a -- "$EXTRAS_DIR/.oh-my-zsh/." "$HOME/.oh-my-zsh/"

        if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
            ok "Тема ark на месте (oh-my-zsh уже установлен)."
        elif command -v git >/dev/null 2>&1; then
            info "oh-my-zsh не установлен — клонирую фреймворк..."
            OMZ_TMP="$HOME/.oh-my-zsh-framework.$$"
            if git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_TMP" 2>/dev/null; then
                cp -a -- "$OMZ_TMP/." "$HOME/.oh-my-zsh/"
                rm -rf -- "$OMZ_TMP"
                ok "oh-my-zsh установлен, тема ark на месте."
            else
                rm -rf -- "$OMZ_TMP"
                manual "Не удалось скачать oh-my-zsh. Вручную:
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh"
            fi
        else
            manual "Нет git — oh-my-zsh не установлен, тема ark не заработает."
        fi
    else
        manual "extras/.oh-my-zsh отсутствует — тема ark не восстановлена."
    fi

    # 4.4 /etc/** (firefox policies, udev-правила и прочее)
    if [[ -d "$EXTRAS_DIR/etc" ]]; then
        local rel target
        while IFS= read -r -d '' f; do
            rel="${f#"$EXTRAS_DIR/etc/"}"
            target="/etc/$rel"
            $SUDO mkdir -p "$(dirname "$target")"
            $SUDO install -m 644 "$f" "$target"
            ok "Установлен /etc/$rel"
        done < <(find "$EXTRAS_DIR/etc" -type f -print0)

        if find "$EXTRAS_DIR/etc" -path '*udev/rules.d/*' -type f | grep -q .; then
            $SUDO udevadm control --reload-rules && $SUDO udevadm trigger || \
                warned "udevadm не отработал, правила применятся после перезагрузки."
        fi
    else
        manual "extras/etc отсутствует — Firefox policies и udev-правила не установлены."
    fi

    # 4.5 ~/Programs
    if [[ -d "$EXTRAS_DIR/Programs" ]] && compgen -G "$EXTRAS_DIR/Programs/*" > /dev/null; then
        mkdir -p "$HOME/Programs"
        local d
        for d in "$EXTRAS_DIR"/Programs/*; do
            base="$(basename "$d")"
            if [[ -e "$HOME/Programs/$base" ]]; then
                ensure_backup_dir
                mv -- "$HOME/Programs/$base" "$BACKUP_DIR/Programs-$base"
            fi
            cp -a -- "$d" "$HOME/Programs/$base"
            ok "Восстановлен ~/Programs/$base"
        done
    else
        manual "extras/Programs пуст — MouseBattery (виджет батареи) не восстановлен."
    fi
}

if (( DO_EXTRAS )); then
    section "extras/"
    restore_extras
fi

# =============================================================================
# 5. Менеджер входа: Ly
# =============================================================================
enable_ly() {
    command -v systemctl >/dev/null 2>&1 || { manual "systemctl не найден — Ly не настроен."; return 0; }
    pacman -Q ly >/dev/null 2>&1 || { manual "Пакет ly не установлен — менеджер входа не настроен."; return 0; }

    local dm_conflict=""
    [[ -e /etc/systemd/system/display-manager.service ]] && dm_conflict="display-manager.service"
    systemctl is-active --quiet display-manager.service 2>/dev/null && \
        dm_conflict="${dm_conflict:+$dm_conflict, }активный DM"

    if [[ -n "$dm_conflict" ]]; then
        manual "Уже настроен другой менеджер входа ($dm_conflict). Отключите его и включите Ly:
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
        manual "getty@tty2 не отключился — включение Ly отменено."
    fi
}

if (( DO_LY )); then
    section "Менеджер входа (Ly)"
    enable_ly
fi

# =============================================================================
# 5.5 RustDesk
# =============================================================================
#  Что нужно на Wayland, чтобы RustDesk заработал сразу:
#    • xdg-desktop-portal + бэкенд hyprland — захват экрана через PipeWire;
#    • /dev/uinput — эмуляция ввода при удалённом управлении;
#    • XDG_CURRENT_DESKTOP=Hyprland — иначе портал не выберет бэкенд.
#  Пакет rustdesk-bin эти зависимости НЕ приносит: только gtk3, xdotool,
#  libxcb, libxfixes, libpulse, libva, libvdpau, pam и gst-plugin-pipewire.
setup_rustdesk() {
    if ! command -v rustdesk >/dev/null 2>&1; then
        manual "rustdesk не установлен — проверьте AUR-пакет rustdesk-bin."
        return 0
    fi

    # --- /dev/uinput: модуль при старте + права для группы input ---
    printf 'uinput\n' | $SUDO tee /etc/modules-load.d/uinput.conf >/dev/null
    $SUDO modprobe uinput 2>/dev/null || warned "modprobe uinput не удался."
    printf '%s\n' 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' \
        | $SUDO tee /etc/udev/rules.d/60-uinput.rules >/dev/null
    $SUDO udevadm control --reload-rules 2>/dev/null || true
    $SUDO udevadm trigger --subsystem-match=misc 2>/dev/null || true
    ok "uinput настроен: модуль + udev-правило."

    # --- группа input ---
    if id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx input; then
        ok "Пользователь уже в группе input."
    elif $SUDO usermod -aG input "$USER"; then
        ok "Пользователь добавлен в группу input (нужен перезаход)."
    else
        manual "Не удалось добавить $USER в группу input: sudo usermod -aG input $USER"
    fi

    if ! id -nG 2>/dev/null | tr ' ' '\n' | grep -qx input; then
        warned "В текущей сессии группы input ещё нет — перезайдите, иначе ввод не заработает."
    fi

    # --- XDG_CURRENT_DESKTOP: по нему портал выбирает бэкенд ---
    case "${XDG_CURRENT_DESKTOP:-}" in
        *Hyprland*) ok "XDG_CURRENT_DESKTOP=Hyprland." ;;
        "")         manual "XDG_CURRENT_DESKTOP пуст — портал не выберет бэкенд.
    Добавьте в hyprland.lua: hl.env(\"XDG_CURRENT_DESKTOP\", \"Hyprland\")" ;;
        *)          warned "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP} — ожидалось Hyprland." ;;
    esac

    # --- перезапуск порталов в пользовательской сессии ---
    if [[ -n "${XDG_RUNTIME_DIR:-}" ]] && command -v systemctl >/dev/null 2>&1; then
        if systemctl --user restart xdg-desktop-portal xdg-desktop-portal-hyprland 2>/dev/null; then
            ok "Порталы перезапущены."
        else
            warned "Не удалось перезапустить порталы (нет графической сессии?)."
        fi
    fi

    # --- проверка, что ScreenCast реально отвечает ---
    if command -v gdbus >/dev/null 2>&1; then
        if gdbus call --session \
             --dest org.freedesktop.portal.Desktop \
             --object-path /org/freedesktop/portal/desktop \
             --method org.freedesktop.DBus.Properties.Get \
             org.freedesktop.portal.ScreenCast version >/dev/null 2>&1; then
            ok "Портал ScreenCast отвечает: захват экрана доступен."
        else
            manual "Портал ScreenCast не отвечает. Проверьте:
    pacman -Q xdg-desktop-portal xdg-desktop-portal-hyprland
    systemctl --user status xdg-desktop-portal-hyprland"
        fi
    else
        warned "gdbus не найден — проверка ScreenCast пропущена."
    fi

    # --- состояние устройства ---
    if [[ -e /dev/uinput ]]; then
        info "/dev/uinput: $(ls -l /dev/uinput 2>/dev/null | awk '{print $1, $3, $4}')"
    else
        manual "/dev/uinput отсутствует — перезагрузитесь, модуль поднимется при старте."
    fi

    # --- служба для доступа без входа в систему (опционально) ---
    if [[ -f /usr/lib/systemd/system/rustdesk.service ]]; then
        if confirm "Включить rustdesk.service (доступ без входа в систему)?"; then
            if $SUDO systemctl enable --now rustdesk; then
                ok "rustdesk.service включён."
            else
                manual "Не удалось включить rustdesk.service."
            fi
        fi
    fi
}

if (( DO_RUSTDESK )); then
    section "RustDesk"
    setup_rustdesk
fi

# =============================================================================
# 6. Проверки
# =============================================================================
section "Проверки"

check_cmd() {
    local c="$1" hint="${2:-}"
    if command -v "$c" >/dev/null 2>&1; then
        ok "команда найдена: $c"
    elif [[ -n "$hint" ]]; then
        manual "команда не найдена: $c ($hint)"
    else
        warned "команда не найдена: $c"
    fi
}

check_cmd hyprland      "пакет hyprland"
check_cmd qs            "пакет quickshell (Super+R/W/T/Z/I/A)"
check_cmd subl          "пакет sublime-text-4 (Super+S)"
check_cmd brightnessctl "клавиши яркости"
check_cmd playerctl     "мультимедиа-клавиши"
check_cmd uwsm          "сессия Hyprland через UWSM"
check_cmd fastfetch     "пакет fastfetch (приветствие в терминале)"
check_cmd rustdesk      "AUR rustdesk-bin"
check_cmd gdbus         "пакет glib2 (проверка портала)"

# --- shell и fastfetch ---
if [[ "${SHELL:-}" == */zsh ]]; then
    ok "Login shell: zsh"
else
    if confirm "Сделать zsh оболочкой по умолчанию (chsh)?"; then
        if chsh -s "$(command -v zsh)"; then
            ok "Login shell изменён на zsh (применится после перезахода)."
        else
            manual "chsh не удался. Вручную: chsh -s /usr/bin/zsh"
        fi
    else
        manual "Login shell не zsh (${SHELL:-неизвестно}) — fastfetch не появится.
    Включите: chsh -s /usr/bin/zsh  и перезайдите"
    fi
fi

if [[ -f "$HOME/.zshrc" ]]; then
    if grep -q 'fastfetch' "$HOME/.zshrc"; then
        ok "~/.zshrc запускает fastfetch."
    else
        manual "В ~/.zshrc нет вызова fastfetch."
    fi
fi

# --- Firefox policies ---
if [[ -f /etc/firefox/policies/policies.json ]]; then
    if command -v jq >/dev/null 2>&1 && \
       jq -e '.policies.Bookmarks' /etc/firefox/policies/policies.json >/dev/null 2>&1; then
        ok "Firefox policies: закладки прописаны."
    else
        warned "policies.json установлен, но ключ Bookmarks не найден."
    fi
    info "Проверка в браузере: about:policies. Закладки применяются к профилю при его создании."
else
    manual "/etc/firefox/policies/policies.json не установлен — закладки Firefox не появятся."
fi

# --- скрипт обоев ---
if [[ -x "$HOME/.local/bin/wallhaven-download.sh" ]]; then
    ok "wallhaven-download.sh на месте и исполняемый."
    for dep in wget jq; do
        command -v "$dep" >/dev/null 2>&1 || manual "Для обоев нужен $dep (pacman -S $dep)"
    done
else
    manual "~/.local/bin/wallhaven-download.sh отсутствует — скачивание обоев не работает."
fi

# --- Hyprland и Lua ---
if command -v hyprland >/dev/null 2>&1; then
    hv="$(hyprland --version 2>/dev/null | head -n1 || true)"
    [[ -n "$hv" ]] && info "Hyprland: $hv"
    info "Конфиг — hyprland.lua: убедитесь, что версия поддерживает Lua."
fi

# --- фактические списки пакетов ---
pacman -Qqe > "$SCRIPT_DIR/packages-current.txt" 2>/dev/null && \
    info "Фактический список пакетов: packages-current.txt"
pacman -Qqm > "$SCRIPT_DIR/foreign-current.txt" 2>/dev/null && \
    info "Пакеты не из репозиториев: foreign-current.txt (сверьте с aur.txt)"

# =============================================================================
# 7. Отчёт
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
  3. Откройте терминал — должен появиться fastfetch.
  4. Панель: qs (если не запущена). Обои: Super+W. Темы: Super+T.
  5. Firefox: закладки появятся в новом профиле; в существующем проверьте about:policies.

Если Ly не запустится — Ctrl+Alt+F3 (или F6) даёт резервную консоль:
tty2 отдан Ly, остальные tty свободны.

RustDesk:
  • первый вход в систему после установки — нужен, чтобы заработала группа input;
  • при первом подключении RustDesk спросит разрешение на захват экрана (портал);
  • если картинка есть, а мышь/клавиатура не работают — проверьте:
        ls -l /dev/uinput          (должно быть crw-rw---- root input)
        id -nG | grep input
  • управление этим ПК по Wayland всё равно ограничено порталом:
    показ экрана работает надёжно, ввод — как повезёт с версией RustDesk.

Альтернатива без DM — ~/.zprofile:

    if [[ -z "${WAYLAND_DISPLAY:-}" && "$(tty 2>/dev/null)" == "/dev/tty1" ]] &&
       uwsm check may-start >/dev/null 2>&1; then
        exec uwsm start hyprland.desktop
    fi

UFW установлен, но НЕ включён: sudo ufw enable
NEXT
