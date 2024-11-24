# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;
  
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Edmonton";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.excludePackages = with pkgs; [ xterm ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.avahi.enable = false;
  services.printing.enable = false;

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

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
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than +10";
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    docker-compose podman-tui
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
  
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos gnome-tour gnome-connections gnome-console
    snapshot yelp   
  ]) ++ (with pkgs.gnome; [
    gnome-calendar gnome-characters gnome-clocks gnome-contacts gnome-logs
    gnome-maps gnome-music gnome-shell-extensions
    epiphany geary totem simple-scan
  ]);
  
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.fil = { pkgs, ... }: {
    home.packages = [
      pkgs.gnome.dconf-editor
      pkgs.gnome.gnome-terminal
      pkgs.gnome.gnome-tweaks
      pkgs.gnome-extension-manager
      pkgs.yaru-theme
      pkgs.jetbrains-mono
      pkgs.mate.mate-terminal
      unstable.ubuntu-sans
      
      pkgs.gnomeExtensions.user-themes
      unstable.gnomeExtensions.astra-monitor
      unstable.gnomeExtensions.caffeine
      unstable.gnomeExtensions.dash-to-dock
      unstable.gnomeExtensions.reboottouefi
      
      pkgs.google-chrome
      unstable.code-cursor
      
      pkgs.awscli2
    ];
    programs = {
      home-manager.enable = true;
    };
    dconf = {
      enable = true;
      settings."org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          user-themes.extensionUuid
          astra-monitor.extensionUuid
          caffeine.extensionUuid
          dash-to-dock.extensionUuid
          reboottouefi.extensionUuid
        ];
      };
      settings."org/gnome/shell/extensions/user-theme".name = "Yaru-blue";
    };

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };

}
