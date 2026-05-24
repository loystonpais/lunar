{den, ...}: {
  lunar.cuda = {
    nixos = {
      config,
      lib,
      ...
    }: {
      nix.settings = {
        substituters = lib.mkBefore ["https://cache.flox.dev"];
        trusted-public-keys = [
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        ];
      };

      nix.registry.nixpkgs-flox-unstable.to = {
        type = "github";
        owner = "flox";
        repo = "nixpkgs";
        ref = "unstable";
      };

      programs.nix-ld = {
        enable = true;
        libraries = [config.boot.kernelPackages.nvidia_x11];
      };
    };

    provides.nixos-cuda-cache = {
      nix.settings = {
        substituters = ["https://cache.nixos.org"];
        trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };
    };
  };
}
