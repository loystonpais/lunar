{
  den,
  lunar,
  inputs,
  ...
}: {
  den.homes.aarch64-darwin."loyston_pais@maple" = {};

  den.aspects.loyston_pais = {
    includes = [
      lunar.dev
      lunar.vscode
      lunar.fonts

      # Cybersecurity
      {
        homeManager = {
          pkgs-stable,
          lib,
          ...
        }: let
          pkgs = pkgs-stable;

          frida-server = rec {
            version = pkgs.python3Packages.frida-python.version;

            fetchServerBin = arch: version: hash:
              pkgs.runCommandNoCC "frida-server-${arch}-${version}" {} ''
                xz -dc ${pkgs.fetchurl {
                  url = "https://github.com/frida/frida/releases/download/${version}/frida-server-${version}-${arch}.xz";
                  inherit hash;
                }} > $out
                chmod +x $out
              '';

            arches = {
              linux-arm64 = fetchServerBin "linux-arm64" version "sha256-XpkCv7rplnHfRxpy7NGLvqA9WP+y3fYaLJKZPU1uiAM=";
              android-arm64 = fetchServerBin "android-arm64" version "sha256-aU71t88yKAYPjAh+dnZGEZEoPAVFdQrfMebCLSwpeW0=";
            };

            bins =
              lib.mapAttrs (
                arch: serverBin:
                  pkgs.writeShellScriptBin "frida-server-bin-${arch}" ''
                    echo "${serverBin}"
                  ''
              )
              arches;

            binsList = builtins.attrValues frida-server.bins;
          };
        in {
          home.packages = with pkgs;
            [
              binwalk

              jadx
              frida-tools
              objection
              android-tools
              apktool

              nmap
              masscan
              rustscan
              nikto
              sqlite
              sqlmap
              httpx

              ffuf
              nmap
              openssl
              sslscan
              tcpdump
              testssl
              wget
              poppler-utils
            ]
            ++ frida-server.binsList;
        };
      }
    ];

    homeManager = {
      pkgs,
      pkgs-stable,
      lib,
      ...
    }: let
      py = pkgs.writeShellScriptBin "py" ''
        exec ${lib.getExe (pkgs.python3.withPackages (p: with p; [requests]))} "$@"
      '';
    in {
      programs.zsh.initContent = ''
        if [ -x /opt/homebrew/bin/brew ]; then
          eval "$(/opt/homebrew/bin/brew shellenv zsh)"
        fi
      '';

      nixpkgs.config.allowUnfree = true;

      home.packages = with pkgs; [
        lsd
        micro
        git
        file
        ripgrep
        ruby
        unar
        jq
        rsync
        gh
        yq-go
        fzf
        bat
        fd
        yazi
        tmux
        zellij
        python3Packages.markitdown
        bun
        p7zip
        util-linux
        util-macros

        python3
        py

        nodejs

        ghostty-bin
        coreutils
        findutils
        diffutils
        gnugrep
        gnused
        gawk
        gnutar

        htop
        btop

        pi-coding-agent

        defaultbrowser

        uv

        pnpm

        tree

        shottr
      ];

      /*
      Externally installed tools
      --------------------------

      android-studio - dmg
      zen-browser - dmg
      brave - dmg
      chrome - dmg
      burp - dmg
      utm - dmg

      copilot - brew
      llama.cpp - brew

      agy - self
      */

      home.shellAliases = {
        ls = "lsd";
        lstr = "lsd -tralh";
        lst = "lsd --tree";
        cpr = "rsync -avhP --partial --inplace";
        l = "lsd -l";
        la = "lsd -la";
      };

      programs.git = {
        enable = true;
        settings = {
          user.name = "loystonpais";
          user.email = "loyston500@gmail.com";
          alias = {
            pu = "push";
            ch = "checkout";
            cm = "commit";
          };
        };
      };

      home.file.".jython-jar".source = pkgs-stable.jython;
      home.file.".jruby-jar".source = pkgs-stable.jruby;

      # home.file.".wordlists".source = "${pkgs.wordlists}/share/wordlists"; #! ModuleNotFoundError: No module named 'pkg_resources'

      home.sessionPath = [
        "$HOME/.npm-global/bin"
        "$HOME/.local/bin"
        "$HOME/Downloads/bin"
      ];

      nix.registry.nixpkgs.flake = inputs.nixpkgs;
      nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

      nixpkgs.config.android_sdk.accept_license = true;
    };
  };
}
