{ pkgs, unstable, config, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    baseIndex = 1;
    keyMode = "vi";
    historyLimit = 10000;
    extraConfig = ''
      set -g set-clipboard on
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Philipp Weiss";
      user.email = "philipp@pweiss.org";
      init.defaultBranch = "main";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      # WireGuard VPN IPs; both hosts must be reachable on wg0.
      nuc = {
        hostname = "10.42.0.2";
        user = "root";
        identityFile = "~/.ssh/id_ed25519_sk";
      };
      bastion = {
        hostname = "10.42.0.1";
        user = "root";
        identityFile = "~/.ssh/id_ed25519_sk";
      };
    };
  };

  home.packages = [
    unstable.claude-code
    pkgs.python3
    pkgs.gcc
    pkgs.rustc
    pkgs.cargo
    pkgs.clippy
    pkgs.rustfmt
    pkgs.rust-analyzer
  ];

  # rust-analyzer needs the standard library's source code to understand `std`.
  # nixpkgs' rustc doesn't include it, so point rust-analyzer at it here.
  home.sessionVariables.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

  home.file.".claude/projects/-home-nixos-nix-config/memory".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix_config/.claude/memory";

  home.stateVersion = "25.11";
}
