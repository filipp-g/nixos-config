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
      <home-manager/nixos>
    ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;  
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 10;
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
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        amdgpuBusId = "PCI:12:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "550.127.05";
        sha256_64bit = "sha256-04TzT10qiWvXU20962ptlz2AlKOtSFocLuO/UZIIauk=";
        sha256_aarch64 = "sha256-3wsGqJvDf8io4qFSqbpafeHHBjbasK5i/W+U6TeEeBY=";
        openSha256 = "sha256-r0zlWPIuc6suaAk39pzu/tp0M++kY2qF8jklKePhZQQ=";
        settingsSha256 = "sha256-cUSOTsueqkqYq3Z4/KEnLpTJAryML4Tk7jco/ONsvyg=";
        persistencedSha256 = "sha256-8nowXrL6CRB3/YcoG1iWeD4OCYbsYKOOPE374qaa4sY=";
      };
    };
  };

  # Enable sound with pipewire.
  security.rtkit.enable = true;
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
  };
  
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = (with pkgs; [
    gnome.dconf-editor
    gnome.gnome-terminal
    gnome.gnome-tweaks
    gnome-extension-manager
    yaru-theme

    gnomeExtensions.user-themes
    cudaPackages.cudatoolkit
    openssl_3_3
    
    dropbox
    google-chrome
    vscode-fhs
    mission-center
    
    awscli2
    git-remote-codecommit
    docker-compose
    nixd
    nodejs_20
    yarn
    prisma-engines
  ]) ++ (with unstable; [
    gnomeExtensions.astra-monitor
    gnomeExtensions.caffeine
    gnomeExtensions.dash-to-dock
    gnomeExtensions.ddterm
    gnomeExtensions.freon
    gnomeExtensions.grand-theft-focus
    gnomeExtensions.reboottouefi
    gnomeExtensions.user-stylesheet-font

    code-cursor
    obsidian
    podman-desktop
    qbittorrent
  ]);

  fonts.packages = (with pkgs; [
    jetbrains-mono
  ]) ++ (with unstable; [
    ubuntu-sans
  ]);

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos gnome-tour gnome-connections gnome-console
    snapshot yelp   
  ]) ++ (with pkgs.gnome; [
    gnome-calendar gnome-characters gnome-clocks gnome-contacts gnome-logs
    gnome-maps gnome-music gnome-shell-extensions
    epiphany geary totem simple-scan
  ]);

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
  
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.fil = { ... }: {
    home.packages = [];
    programs = {
      home-manager.enable = true;
    };

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };

}
