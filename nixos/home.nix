# Пользовательский слой: пакеты + конфиги из репозитория Ark-by/arch.
# Подключён как home-manager.users.ark в flake.nix.

{ config, pkgs, lib, inputs, ... }:
let
  # TODO: путь, куда вы клонируете репозиторий на NixOS.
  repo = "/home/ark/dotfiles";
in
{
  home.username = "ark";
  home.homeDirectory = "/home/ark";
  home.stateVersion = "25.11";

  # ── пакеты (из packages.txt, для пользовательского уровня) ─────────────────
  home.packages = with pkgs; [
    # терминал и утилиты
    kitty
    btop
    htop
    fastfetch
    jq
    wget
    usbutils
    smartmontools
    tcpdump
    libnetfilter_queue
    nano
    vim
    luajit                      # нужен для Lua-конфига Hyprland

    # Wayland / Hyprland
    grim                        # скриншот
    slurp                       # выделение области
    quickshell                  # ваш бар
    uwsm                        # менеджер сессии (withUWSM в configuration.nix)
    dunst                       # уведомления

    # файлы
    kdePackages.dolphin
    kdePackages.polkit-kde-agent-1

    # сеть и сервисы
    cloudflare-warp
    bind                        # DNS-сервер (в packages.txt)
    gh                          # github-cli
    openssh

    # приложения
    firefox
    sublime4                    # sublime-text-4
    rustdesk
    pipx

    # темы/шрифты ставятся системно в configuration.nix
  ];

  # ── zsh (zsh-autosuggestions, zsh-syntax-highlighting) ───────────────────
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -la";
      # TODO: перенести ваши алиасы из ~/.zshrc
    };
  };

  # ── git ───────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    userName = "Ark-by";                       # TODO: проверить
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # ── конфиги из репозитория ────────────────────────────────────────────────
  # Обычные конфиги: симлинк в read-only стор, приложение их не переписывает.
  xdg.configFile = {
    "kitty".source            = "${repo}/config/kitty";
    "fastfetch".source        = "${repo}/config/fastfetch";
    "themes".source           = "${repo}/config/themes";
    "dolphinrc".source        = "${repo}/config/dolphinrc";
    "trashrc".source          = "${repo}/config/trashrc";

    # QuickShell: сам код статичен, но два файла — состояние, пикер их меняет.
    "quickshell".source = "${repo}/config/quickshell";

    "quickshell/theme.json".source =
      config.lib.file.mkOutOfStoreSymlink "${repo}/config/quickshell/theme.json";
    "quickshell/wallpaper.txt".source =
      config.lib.file.mkOutOfStoreSymlink "${repo}/config/quickshell/wallpaper.txt";
  };

  # Hyprland: конфиг нативный Lua (hyprland.lua + keybinds.lua + colors.lua),
  # поэтому раскладка репозитория совпадает с ~/.config/hypr один-к-одному —
  # генерировать .conf не нужно, каталог симлинкается целиком.
  #
  # Требование: версия Hyprland с поддержкой Lua. Проверить до сборки:
  #   nix eval --raw nixpkgs#hyprland.version
  # Если в nixos-unstable версия старее вашей — переопределить пакет:
  #   programs.hyprland.package = pkgs.hyprland.overrideAttrs ... (или флейк upstream)
  xdg.configFile."hypr".source = "${repo}/config/hypr";

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    EDITOR = "vim";
  };

  programs.home-manager.enable = true;
}
