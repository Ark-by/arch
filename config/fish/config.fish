# ~/.config/fish/config.fish — окружение ark

if status is-interactive
    # своё приветствие вместо стандартного
    set -g fish_greeting ""
    if type -q fastfetch
        fastfetch
    end
end

# редактор по умолчанию (Super+S в Hyprland открывает его же в kitty)
set -gx EDITOR micro
set -gx VISUAL micro
set -gx PAGER less
set -gx LESS "-R"

# локальные бинарники первыми в PATH (set-theme, wallhaven-download.sh)
fish_add_path --move --prepend "$HOME/.local/bin"
