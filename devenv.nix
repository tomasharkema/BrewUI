{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # https://devenv.sh/basics/
  # env.GREET = "devenv";

  # https://devenv.sh/packages/
  # packages = with pkgs; [swiftlint swiftformat];

  # https://devenv.sh/languages/
  languages = {
    # swift.enable = true;
  };

  # https://devenv.sh/pre-commit-hooks/
  pre-commit.hooks = {
    shellcheck.enable = true;
    shfmt.enable = true;
  };
  # See full reference at https://devenv.sh/reference/options/
}
