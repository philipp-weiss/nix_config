{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Philipp Weiss";
      user.email = "philipp@pweiss.org";
      init.defaultBranch = "main";
    };
  };

  home.packages = with pkgs; [
    claude-code
  ];

  home.stateVersion = "25.11";
}
