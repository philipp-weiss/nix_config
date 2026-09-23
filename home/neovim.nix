{ config, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # No plugin here needs the Ruby or Python providers; these become the
    # upstream defaults in 26.05 and setting them keeps them out of the closure.
    withRuby = false;
    withPython3 = false;

    initLua = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      vim.opt.ignorecase = true
      vim.opt.smartcase = true

      -- Inside VS Code, Neovim is only the editing engine: VS Code owns the
      -- LSP, completion, diagnostics and file tree. Plugins that draw UI fight
      -- it, so the vscode branch stays deliberately bare and hands the few
      -- actions that must stay VS Code's job back to VS Code.
      if vim.g.vscode then
        local vscode = require("vscode")
        vim.keymap.set("n", "<leader>f", function() vscode.action("editor.action.formatDocument") end)
        vim.keymap.set("n", "<leader>r", function() vscode.action("editor.action.rename") end)
        vim.keymap.set("n", "<leader>a", function() vscode.action("editor.action.quickFix") end)
        vim.keymap.set("n", "gr", function() vscode.action("editor.action.goToReferences") end)
        return
      end

      -- Terminal-only from here down.
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 4
      vim.opt.tabstop = 4
      vim.opt.signcolumn = "yes"
      vim.opt.undofile = true
    '';
  };

  # Remote-WSL machine settings. The workspace-side extensions must be pointed
  # at the binaries this flake installs: left alone they download their own,
  # which are dynamically linked against paths that don't exist on NixOS.
  home.file.".vscode-server/data/Machine/settings.json".text = builtins.toJSON {
    "vscode-neovim.neovimExecutablePaths.linux" = "${config.home.profileDirectory}/bin/nvim";
    "rust-analyzer.server.path" = "${config.home.profileDirectory}/bin/rust-analyzer";
  };
}
