{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  git-hooks.hooks = {
    check-added-large-files.enable = true;

    # flake-checker.enable = true;
  };
}
