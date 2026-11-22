# Этап 1: home-manager на Arch, без переустановки.
# Задача первого шага — НЕ трогать существующие конфиги, только пакеты.
# Ваши ~/.config/hypr, ~/.config/quickshell и остальное остаются как есть.

{ config, pkgs, lib, ... }:
{
  home.username = "ark";              # TODO: сверить с `whoami` на Arch
  home.homeDirectory = "/home/ark";   # TODO: сверить с $HOME
  home.stateVersion = "25.11";

  # Пакеты, которые удобно держать в Nix. Начните с малого: если что-то
  # уже стоит из pacman, команда не конфликтует — Nix кладёт своё в профиль.
  home.packages = with pkgs; [
    btop
    fastfetch
    jq
    ripgrep
    fd
    tree
  ];

  programs.git = {
    enable = true;
    userName = "Ark-by";              # TODO: ваш git-email
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # ── Конфиги пока НЕ подключаем ────────────────────────────────────────────
  # Когда убедитесь, что home-manager работает стабильно, включите по одному:
  #
  # xdg.configFile."kitty".source = "/home/ark/dotfiles/config/kitty";
  #
  # home-manager при первом switch сделает резервную копию существующей папки
  # с суффиксом .bak (backupFileExtension в flake.nix), но лучше включать
  # осознанно и по одному пункту.

  programs.home-manager.enable = true;
}
