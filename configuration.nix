# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };

  monitorsXmlContent = builtins.readFile /home/fil/.config/monitors.xml;
  monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
in
{
  imports = [
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

  systemd.services.plex.serviceConfig =
    let
      pidFile = "${config.services.plex.dataDir}/Plex Media Server/plexmediaserver.pid";
    in
    {
      KillSignal = lib.mkForce "SIGKILL";
      Restart = lib.mkForce "no";
      TimeoutStopSec = 10;
      ExecStop = pkgs.writeShellScript "plex-stop" ''
        ${pkgs.procps}/bin/pkill --signal 15 --pidfile "${pidFile}"

        # Wait until plex service has been shutdown
        # by checking if the PID file is gone
        while [ -e "${pidFile}" ]; do
          sleep 0.1
        done

        ${pkgs.coreutils}/bin/echo "Plex shutdown successful"
      '';
      PIDFile = lib.mkForce "";
    };

  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
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
    hostName = "nix";
    networkmanager.enable = true;
    firewall = {
      allowedTCPPorts = [ 32400 ];
      logReversePathDrops = true;
      # wireguard trips rpfilter up
      extraCommands = ''
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
        ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
      '';
      extraStopCommands = ''
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
        ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
      '';
    };
  };

  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.fil = {
    isNormalUser = true;
    description = "fil";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
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
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "570.144";
        sha256_64bit = "sha256-wLjX7PLiC4N2dnS6uP7k0TI9xVWAJ02Ok0Y16JVfO+Y=";
        openSha256 = "sha256-PATw6u6JjybD2OodqbKrvKdkkCFQPMNPjrVYnAZhK/E=";
        settingsSha256 = "sha256-VcCa3P/v3tDRzDgaY+hLrQSwswvNhsm93anmOhUymvM=";
        usePersistenced = false;
      };
    };
  };

  services = {
    fstrim.enable = true;
    avahi.enable = false;
    printing.enable = false;
    xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      excludePackages = with pkgs; [ xterm ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    flatpak.enable = true;
    plex = {
      enable = true;
      package = unstable.plex;
    };
  };

  programs = {
    git.enable = true;
    java = {
      enable = true;
      package = pkgs.jdk;
    };
    gamemode.enable = true;
    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ptyxis";
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages =
    (with pkgs; [
      dconf-editor
      gnome-extension-manager
      gnome-tweaks
      nvd
      xdg-utils
      yaru-theme

      brave
      mission-center
      ptyxis

      cudaPackages.cudatoolkit
      docker-compose
      nodejs_20
      openssl_3_3
      yarn

      helix
      nixd
      nixfmt-rfc-style
      wl-clipboard
    ])
    ++ (with unstable; [
      vscode-fhs
      awscli2
      prisma-engines
    ])
    ++ (with unstable.gnomeExtensions; [
      ddterm
      freon
    ]);

  fonts.packages = with pkgs; [
    ubuntu-sans
    ubuntu-classic
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-connections
    gnome-console
    gnome-contacts
    gnome-logs
    gnome-maps
    gnome-music
    gnome-photos
    gnome-shell-extensions
    gnome-tour
    simple-scan
    snapshot
    totem
    yelp
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
