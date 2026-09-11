{
  den,
  lunar,
  inputs,
  lib,
  ...
}: let
  mkPkgsStable = pkgs:
    import inputs.nixpkgs-stable {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      config.android_sdk.accept_license = true;
    };
in {
  flake.den = den;

  den.schema.user.includes = [den._.mutual-provider];
  den.schema.home.includes = [den._.mutual-provider];

  den.default = {
    includes = [
      den.provides.define-user
      den.provides.hostname
      den._.inputs'
      den._.self'
    ];

    # Add packages from /packages
    packages = {pkgs, ...}: let
      importPackages = dir:
        builtins.listToAttrs (
          map (name: {
            name = lib.removeSuffix ".nix" name;
            value = pkgs.callPackage (dir + "/${name}") {};
          }) (builtins.attrNames (builtins.readDir dir))
        );

      packages = importPackages "${inputs.self.outPath}/packages";
    in
      packages;

    nixos = {
      pkgs,
      config,
      ...
    }: {
      _module.args.pkgs-stable = mkPkgsStable pkgs;

      nixpkgs = {
        config = {
          allowUnfree = lib.mkDefault true;
          allowUnfreePredicate = lib.mkDefault (_: true);
        };

        system.stateVersion = lib.mkDefault "23.11";
      };

      nix.settings = {
        substituters = [
          "https://cache.nixos.org/"
          # "https://nix-community.cachix.org?priority=5" # CACHE TOO SLOW
        ];
        trusted-public-keys = [
          # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        experimental-features = ["nix-command" "flakes"];
        lazy-trees = true;
      };

      nix.registry = {
        lunar.flake = inputs.self;
        nixpkgs.flake = inputs.nixpkgs;

        nixpkgs-stable.flake = inputs.nixpkgs-stable;
      };

      system.nixos.tags = ["lunar"];

      environment.variables = rec {
        LUNAR_NIXPKGS_REV = inputs.nixpkgs.rev;
        LUNAR_NIXPKGS_URL = "github:NixOS/nixpkgs/${LUNAR_NIXPKGS_REV}";

        LUNAR_NIXPKGS_STABLE_REV = inputs.nixpkgs-stable.rev;
        LUNAR_NIXPKGS_STABLE_URL = "github:NixOS/nixpkgs/${LUNAR_NIXPKGS_STABLE_REV}";
      };
    };

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      _module.args.pkgs-stable = mkPkgsStable pkgs;
      home.stateVersion = lib.mkDefault "25.11";
    };
  };
}
