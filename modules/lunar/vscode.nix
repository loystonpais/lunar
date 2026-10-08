{
  den,
  inputs,
  ...
}: {
  lunar.vscode = let
    mkCommonSettings = {
      pkgs,
      lib,
      ...
    }: {
      "update.mode" = "none";
      "continue.telemetryEnabled" = false;
      "diffEditor.ignoreTrimWhitespace" = false;
      "extensions.autoUpdate" = "off";
      "explorer.confirmDragAndDrop" = false;
      "git.enableSmartCommit" = true;
      "redhat.telemetry.enabled" = false;
      "security.workspace.trust.untrustedFiles" = "open";
      "telemetry.enableCrashReporter" = false;
      "telemetry.enableTelemetry" = false;
      "telemetry.telemetryLevel" = "off";
      "workbench.sideBar.location" = "right";
      "terminal.integrated.copyOnSelection" = true;
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.cursorStyle" = "line";
      "terminal.integrated.persistentSessionScrollback" = 1000;
      "terminal.integrated.ignoreBracketedPasteMode" = false;
      "terminal.integrated.rightClickBehavior" = "paste";
      "terminal.integrated.scrollback" = 3000;
      "window.closeOnFileDelete" = true;

      "workbench.colorTheme" = "Dark 2026";
      "workbench.preferredDarkColorTheme" = "Dark 2026";

      "workbench.iconTheme" = "vscode-icons";
      "workbench.statusBar.visible" = true;
      "editor.formatOnSave" = true;
      "editor.wordWrap" = "on";
      "editor.wordWrapColumn" = 120;
      "editor.fontLigatures" = true;
      "editor.tabSize" = 2;

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = lib.getExe pkgs.nixd;
      "nix.formatterPath" = lib.getExe pkgs.alejandra;

      "python.analysis.typeCheckingMode" = "standard";
      "pylsp.executable" = lib.getExe pkgs.python3Packages.python-lsp-server;

      "rubyLsp.bundleGemfile" = "";
      "rubyLsp.customRubyCommand" = lib.getExe' pkgs.ruby "ruby";
      "rubyLsp.lspPath" = lib.getExe' pkgs.rubyPackages.ruby-lsp "ruby-lsp";
      "rubyLsp.pullDiagnosticsOn" = "save";
      "rubyLsp.rubyVersionManager" = "none";
      "[ruby]" = {
        editor.defaultFormatter = "shopify.ruby-lsp";
        editor.formatOnSave = true;
      };
    };

    mkCommonExtensions = {pkgs, ...}: (with pkgs.vscode-extensions;
      with pkgs.vscode-marketplace; [
        # Essential Nix support
        bbenoist.nix
        jnoortheen.nix-ide
        kamadorueda.alejandra
        jeff-hykin.better-nix-syntax

        # Essential workflow
        mkhl.direnv
        ms-vscode-remote.remote-ssh
        christian-kohler.path-intellisense

        donjayamanne.githistory

        davidanson.vscode-markdownlint

        ms-toolsai.jupyter
        charliermarsh.ruff
        ms-python.python
        ms-python.vscode-pylance
        #elixir-lsp.vscode-elixir

        jnoortheen.xonsh
        thenuprojectcontributors.vscode-nushell-lang

        hashicorp.terraform
        ms-azuretools.vscode-containers
        ms-vscode-remote.remote-containers
        github.vscode-github-actions
        github.vscode-pull-request-github
        gitlab.gitlab-workflow

        redhat.vscode-yaml
        redhat.vscode-xml

        mechatroner.rainbow-csv

        # Rust
        rust-lang.rust-analyzer
        tamasfe.even-better-toml

        # Go
        golang.go

        # Gleam
        # gleam.gleam #! BUILD FAILURE

        # Haskell
        haskell.haskell

        # C/C++
        # llvm-vs-code-extensions.vscode-clangd # Conflicts with ms-vscode.cpptools
        ms-vscode.makefile-tools
        #TODO: fix this not working on darwin. ms-vscode.cpptools
        ms-vscode.cmake-tools
        xaver.clang-format

        # Essential UI/UX
        pkief.material-icon-theme
        eamodio.gitlens
        mhutchie.git-graph
        vivaxy.vscode-conventional-commits
        aaron-bond.better-comments
        editorconfig.editorconfig
        oderwat.indent-rainbow
        shardulm94.trailing-spaces
        kisstkondoros.vscode-gutter-preview

        # Workflow
        datakurre.devenv

        # Templating
        karunamurti.tera

        # Others
        kdl-org.kdl
        legale.dts-formatter

        tomoki1207.pdf

        # Ruby
        shopify.ruby-lsp

        # Lua
        sumneko.lua
      ]);
  in {
    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.vscode];

      # adds vscode extensions from marketplace
      nixpkgs.overlays = [
        inputs.nix-vscode-extensions.overlays.default
      ];
    };

    homeManager = {
      pkgs,
      lib,
      ...
    }: let
      commonSettings = mkCommonSettings {
        inherit pkgs;
        inherit lib;
      };

      commonExtensions = mkCommonExtensions {
        inherit pkgs;
        inherit lib;
      };
    in {
      config = {
        programs.vscode = {
          enable = true;

          profiles = {
            # 1. Default Profile: Core configuration + Essential Nix
            default = {
              userSettings = commonSettings;
              extensions = commonExtensions;
            };

            web = {
              userSettings = commonSettings;
              extensions =
                commonExtensions
                ++ (with pkgs.vscode-extensions;
                  with pkgs.vscode-marketplace; [
                    # JS/TS
                    dbaeumer.vscode-eslint
                    yoavbls.pretty-ts-errors
                    esbenp.prettier-vscode

                    # React / Next.js
                    # dsznajder.es7-react-js-snippets #! BUILD FAILURE
                    pulkitgangwar.nextjs-snippets

                    # Styles
                    styled-components.vscode-styled-components
                    vincaslt.highlight-matching-tag
                    formulahendry.auto-close-tag
                    formulahendry.auto-rename-tag

                    # Frameworks
                    shopify.ruby-lsp
                    shopify.ruby-extensions-pack

                    # Web Tools
                    ms-vscode.live-server
                    wix.vscode-import-cost

                    # Docs
                    yzhang.markdown-all-in-one
                    davidanson.vscode-markdownlint
                    unifiedjs.vscode-mdx
                  ]);
            };

            flutter = {
              userSettings = commonSettings;
              extensions =
                commonExtensions
                ++ (with pkgs.vscode-extensions;
                  with pkgs.vscode-marketplace; [
                    dart-code.dart-code
                    dart-code.flutter
                    nash.awesome-flutter-snippets

                    # Android
                    # vscjava.vscode-gradle #! BUILD FAILURE
                    dotjoshjohnson.xml
                    mathiasfrohlich.kotlin
                  ]);
            };
          };
        };
      };
    };

    provides.godot-integration = {
      homeManager = {
        pkgs,
        lib,
        ...
      }: let
        commonSettings = mkCommonSettings {
          inherit pkgs;
          inherit lib;
        };

        commonExtensions = mkCommonExtensions {
          inherit pkgs;
          inherit lib;
        };
      in {
        programs.vscode.profiles = {
          godot = {
            userSettings =
              commonSettings
              // {
                "csharp.toolsDotnetPath" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
                "dotnetAcquisitionExtension.sharedExistingDotnetPath" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
                "dotnetAcquisitionExtension.existingDotnetPath" = [
                  {
                    "extensionId" = "ms-dotnettools.csharp";
                    "path" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
                  }
                  {
                    "extensionId" = "ms-dotnettools.csdevkit";
                    "path" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
                  }
                  {
                    "extensionId" = "woberg.godot-dotnet-tools";
                    "path" = "${pkgs.dotnet-sdk_8}/bin/dotnet";
                  }
                ];
                "godotTools.lsp.serverPort" = 6005;
                "omnisharp" = {
                  "path" = "${pkgs.omnisharp-roslyn}/bin/OmniSharp";
                  "sdkPath" = "${pkgs.dotnet-sdk_9}";
                  "dotnetPath" = "${pkgs.dotnet-sdk_9}/bin/dotnet";
                };
              };
            extensions =
              commonExtensions
              ++ (with pkgs.vscode-extensions;
                with pkgs.vscode-marketplace; [
                  geequlim.godot-tools
                  woberg.godot-dotnet-tools
                  ms-dotnettools.csdevkit
                  ms-dotnettools.csharp
                  ms-dotnettools.vscode-dotnet-runtime
                ]);
          };
        };

        home.packages = [
          pkgs.dotnetCorePackages.dotnet_9.sdk
        ];
      };
    };
  };
}
