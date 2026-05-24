{
  description = "Lunar NixOS Configuration";

  outputs = inputs: let
    withSystem = system: let
      inputs' = builtins.mapAttrs (_: builtins.mapAttrs (_: value: value.${system})) inputs;
      self'.packages.hello = inputs.nixpkgs.legacyPackages.${system}.hello;
    in
      cb: cb {inherit inputs' self';};
  in
    (inputs.nixpkgs.lib.evalModules {
      modules = [
        inputs.den.flakeModule
        (inputs.import-tree ./modules)
      ];
      specialArgs.inputs = inputs;
      specialArgs.withSystem = withSystem;
    }).config.flake;

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";

    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

    finix.url = "github:finix-community/finix?ref=main";

    import-tree.url = "github:vic/import-tree";

    flake-aspects.url = "github:vic/flake-aspects";

    den.url = "github:vic/den";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # blender-bin = {
    #   url = "github:edolstra/nix-warez?dir=blender";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    jail-nix.url = "sourcehut:~alexdavid/jail.nix";

    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    droidspaces = {
      url = "github:loystonpais/Droidspaces-OSS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
