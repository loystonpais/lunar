{
  den,
  inputs,
  ...
}: {
  lunar.neovim = {
    homeManager.imports = [
      inputs.lazyvim.homeManagerModules.default
    ];

    provides.astronvim = {
      homeManager = {
        pkgs,
        lib,
        ...
      }: {
        home.packages = [
          (pkgs.writeShellScriptBin "astronvim" ''
            export NVIM_APPNAME=astronvim
            exec ${lib.getExe pkgs.neovim} "$@"
          '')
        ];

        xdg.desktopEntries.astronvim = {
          name = "AstroNvim";
          genericName = "Text Editor";
          exec = "astronvim %F";
          icon = "${inputs.self.outPath}/assets/astronvim.svg";
          terminal = true;
          categories = ["Utility" "TextEditor" "Development"];
          mimeType = [
            "text/plain"
            "text/x-makefile"
            "text/x-c++src"
            "text/x-csrc"
            "text/x-chdr"
            "text/x-python"
            "text/x-java"
            "text/x-go"
            "text/x-rust"
            "application/x-shellscript"
          ];
        };
      };
    };

    provides.lazyvim-declarative = {
      homeManager = {
        pkgs,
        lib,
        ...
      }: {
        home.packages = [
          (pkgs.writeShellScriptBin "lazyvim" ''
            export NVIM_APPNAME=lazyvim
            exec ${lib.getExe pkgs.neovim} "$@"
          '')
        ];

        programs.lazyvim = {
          enable = true;

          appName = "lazyvim";

          extraPackages = with pkgs; [
            # LSP servers
            nixd
            pyright

            # Formatters
            black
            alejandra

            # Tools
            ripgrep
            fd
          ];

          extras = {
            editor.telescope.enable = true;
            ui.alpha.enable = true;

            lang.nix = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };

            lang.python = {
              enable = true;
              installDependencies = true;
            };

            lang.git = {
              enable = true;
            };

            lang.toml.enable = true;
            lang.yaml.enable = true;

            lang.markdown.enable = true;
            lang.json.enable = true;

            lang.rust = {
              enable = true;

              config = ''
                return {
                  "neovim/nvim-lspconfig",
                  opts = {
                    servers = {
                      rust_analyzer = {
                        settings = {
                          ["rust-analyzer"] = {
                            cargo = { features = "all" },
                          },
                        },
                      },
                    },
                  },
                }
              '';
            };
          };

          # IMPORTANT: Extras don't install treesitter parsers automatically
          # You must add them manually for syntax highlighting
          treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
            nix
            python
            rust
            bash
          ];
        };
      };
    };
  };
}
