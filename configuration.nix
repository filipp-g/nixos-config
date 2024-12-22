# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
  
  monitorsXmlContent = builtins.readFile /home/fil/.config/monitors.xml;
  monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "kernel.nmi_watchdog" = 0;
    };
  };

  security = {
    rtkit.enable = true;
    protectKernelImage = true;
    lockKernelModules = true;
    pam.services.login.failDelay = {
      enable = true;
      delay = 8000000;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 5;
  };

  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than +10";
    };
    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 32400 ];
  };

  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_CA.UTF-8";

  services = {
    fstrim.enable = true;
    avahi.enable = false;
    printing.enable = false;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      excludePackages = with pkgs; [ xterm ];
      # keymap
      xkb.layout = "us";
      xkb.variant = "";
    };
    flatpak.enable = true;
    plex.enable = true;
  };

  hardware = {
    pulseaudio.enable = false;
    nvidia = {
      open = false;
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        amdgpuBusId = "PCI:12:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.fil = {
    isNormalUser = true;
    description = "fil";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = [];
  };

  programs = {
    firefox.enable = true;
    git.enable = true;
    java = {
      enable = true;
      package = pkgs.jdk17;
    };
    steam.enable = true;
    gamemode.enable = true;
    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ptyxis";
    };
  };
  
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = (with pkgs; [
    gnome-tweaks gnome-extension-manager gnomeExtensions.user-themes
    dconf-editor xdg-utils yaru-theme ptyxis

    cudaPackages.cudatoolkit
    openssl_3_3
    
    dropbox
    google-chrome
    mission-center
    vscode-fhs
    
    awscli2 git-remote-codecommit docker-compose
    nodejs_20 prisma-engines yarn
    nixd
  ]) ++ (with unstable; [
    code-cursor

    podman-desktop
    obsidian
    qbittorrent
    lutris
    mangohud
  ]) ++ (with unstable.gnomeExtensions; [
    astra-monitor caffeine dash-to-dock ddterm freon
    grand-theft-focus reboottouefi user-stylesheet-font
  ]);

  fonts.packages = with pkgs; [
    jetbrains-mono ubuntu-sans
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-calendar gnome-characters gnome-clocks gnome-console gnome-connections
    gnome-contacts gnome-logs gnome-maps gnome-music gnome-photos gnome-tour
    gnome-shell-extensions snapshot yelp epiphany geary totem simple-scan
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
