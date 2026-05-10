{ pkgs, unstable, ... }:
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
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Philipp Weiss";
      user.email = "philipp@pweiss.org";
      init.defaultBranch = "main";
    };
  };

  home.packages = [
    unstable.claude-code
  ];

  home.stateVersion = "25.11";
}
