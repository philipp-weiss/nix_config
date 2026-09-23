{ config, ... }:
{
  # Remote-WSL machine settings. VS Code's rust-analyzer extension downloads
  # its own server binary by default; that binary is dynamically linked against
  # paths that don't exist on NixOS and silently fails to start. Point it at
  # the rust-analyzer from home.packages instead.
  home.file.".vscode-server/data/Machine/settings.json".text = builtins.toJSON {
    "rust-analyzer.server.path" = "${config.home.profileDirectory}/bin/rust-analyzer";
  };
}
