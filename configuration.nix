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

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  boot.kernelPackages = pkgs.linuxPackages_latest;

  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"
  ];

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 32400 ];
  };

  # Set your time zone.
  time.timeZone = "America/Edmonton";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  services = {
    avahi.enable = false;
    printing.enable = false;
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      excludePackages = with pkgs; [ xterm ];
      # keymap
      xkb.layout = "us";
      xkb.variant = "";
    };
    plex.enable = true;
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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
    packages = with pkgs; [];
  };

  programs = {
    firefox.enable = true;
    git.enable = true;
    java = {
      enable = true;
      package = pkgs.jdk17;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
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
    jetbrains-mono
    
    gnomeExtensions.user-themes
    
    dropbox
    google-chrome
    vscode-fhs
    mission-center
    
    awscli2
    docker-compose
    podman-tui
    nixd
  ]) ++ (with unstable; [
    ubuntu-sans
    
    gnomeExtensions.astra-monitor
    gnomeExtensions.caffeine
    gnomeExtensions.dash-to-dock
    gnomeExtensions.freon
    gnomeExtensions.grand-theft-focus
    gnomeExtensions.reboottouefi
    gnomeExtensions.user-stylesheet-font

    code-cursor
    obsidian
    qbittorrent
  ]);

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos gnome-tour gnome-connections gnome-console
    snapshot yelp   
  ]) ++ (with pkgs.gnome; [
    gnome-calendar gnome-characters gnome-clocks gnome-contacts gnome-logs
    gnome-maps gnome-music gnome-shell-extensions
    epiphany geary totem simple-scan
  ]);

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than +10";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
  
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.fil = { pkgs, ... }: {
    home.packages = [];
    programs = {
      home-manager.enable = true;
    };

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };

}
