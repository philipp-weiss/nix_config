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
      # Tailnet IPs from the headscale-managed VPN; both hosts must be joined.
      nuc = {
        hostname = "100.64.0.2";
        user = "root";
        identityFile = "~/.ssh/id_ed25519_sk";
      };
      bastion = {
        hostname = "100.64.0.4";
        user = "root";
        identityFile = "~/.ssh/id_ed25519_sk";
      };
    };
  };

  home.packages = [
    unstable.claude-code
    pkgs.python3
  ];

  home.file.".claude/projects/-home-nixos-nix-config/memory".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix_config/.claude/memory";

  home.stateVersion = "25.11";
}
