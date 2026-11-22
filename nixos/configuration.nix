# Системный слой. Собран по packages.txt + aur.txt из репозитория Ark-by/arch.
# TODO-пункты помечены: их нужно подтвердить под конкретное железо.

{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix   # генерируется на месте: nixos-generate-config
  ];

  # ── загрузка ────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;      # меню с поколениями
  boot.loader.efi.canTouchEfiVariables = true;

  # Ryzen 7 2700 (Zen+) — обычное ядро надёжнее для драйвера NVIDIA,
  # чем linuxPackages_latest: свежее ядро иногда опережает поддержку в драйвере.
  boot.kernelPackages = pkgs.linuxPackages;

  hardware.cpu.amd.updateMicrocode = true;     # amd-ucode из packages.txt

  # ── GPU: NVIDIA RTX 3050 (Ampere) ─────────────────────────────────────────
  # Проприетарный драйвер: nouveau на Ampere в разы слабее, а видеопамять
  # используется неэффективно (важно, если когда-нибудь понадобятся CUDA/Blender).
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;                               # для Ampere стабильнее закрытый модуль
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;
  };

  hardware.graphics = {
    enable = true;                              # mesa
    enable32Bit = false;                        # Steam не нужен → 32-битные библиотеки не тянем
  };

  hardware.enableRedistributableFirmware = true; # linux-firmware

  # Переменные для NVIDIA + Wayland (Hyprland)
  environment.sessionVariables = {
    NIXOS_OZONE_WL           = "1";
    LIBVA_DRIVER_NAME        = "nvidia";
    GBM_BACKEND              = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # ── сеть ───────────────────────────────────────────────────────────────────
  networking.hostName = "desktop";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;            # вместо ufw
  time.timeZone = "Europe/Astrakhan";

  # ── звук (pipewire-alsa, pipewire-pulse, wireplumber) ──────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  sound.enable = false;                         # pipewire сам управляет

  # ── Hyprland ───────────────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    withUWSM = true;                            # uwsm из packages.txt
    xwayland.enable = true;
  };

  # порталы: без них не работают скриншоты, диалоги, авторизация
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # ── вход в систему ─────────────────────────────────────────────────────────
  # greetd + tuigreet: список сессий берётся из wayland-sessions, где Hyprland
  # зарегистрирован модулем programs.hyprland. Выбираете в меню при входе.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --sessions /run/current-system/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # Вариант с ly (был в packages.txt) — если захотите TUI-логин вместо greetd:
  # services.displayManager.ly.enable = true;
  # ВНИМАНИЕ: не включайте ly и greetd одновременно.

  security.polkit.enable = true;                # polkit-kde-agent
  services.gnome.gnome-keyring.enable = true;   # хранилище ключей для приложений

  # ── zram (zram-generator в packages.txt) ──────────────────────────────────
  zramSwap.enable = true;

  # ── шрифты (noto-fonts, noto-fonts-emoji, ttf-jetbrains-mono-nerd) ────────
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
  ];

  # ── пользователь ──────────────────────────────────────────────────────────
  users.users.ark = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "audio" ];
    shell = pkgs.zsh;
    # пароль задать: sudo passwd ark
  };
  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # ── SSH (openssh в packages.txt) ──────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;    # только ключи
  };

  # ── nix ───────────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;            # sublime, rustdesk и т. п.

  system.stateVersion = "25.11";
}
