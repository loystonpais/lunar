{den, ...}: {
  lunar.zed = {
    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        zed-editor
      ];
    };

    homeManager = {
      osConfig,
      lib,
      pkgs,
      ...
    }: {
      config = {
        # home.packages = [
        #   (pkgs.lunar.writeKioServiceMenu "open-with-zeditor" ''
        #     [Desktop Entry]
        #     Type=Service
        #     X-KDE-ServiceTypes=KonqPopupMenu/Plugin
        #     MimeType=inode/directory;
        #     Actions=openWithZed;
        #     X-KDE-Priority=TopLevel
        #     Icon=zed

        #     [Desktop Action openWithZed]
        #     Name=Open with Zed
        #     Icon=zed
        #     Exec=zeditor "%f"
        #   '')
        # ];

        xdg.configFile."zed/tasks.json".text = builtins.toJSON [
          {
            label = "ruby eval: '$ZED_SELECTED_TEXT'";
            command = "ruby";
            args = ["ruby" "-e" "$ZED_SELECTED_TEXT"];
            use_new_terminal = false;
          }
          {
            label = "nix eval: $ZED_SELECTED_TEXT";
            command = "nix";
            args = ["eval" "--expr" "let pkgs = import <nixpkgs> {}; lib = pkgs.lib; in $ZED_SELECTED_TEXT"];
            use_new_terminal = false;
          }
          {
            label = "py eval: $ZED_SELECTED_TEXT";
            command = "python3";
            args = ["-c" "print($ZED_SELECTED_TEXT)"];
            use_new_terminal = false;
          }
        ];

        programs.zed-editor = {
          enable = true;
          extensions = [
            "nix"
            "toml"
            "html"
            "html-jinja"
            "xml"
            "lua"
            "typos"
            "kotlin"
            "csharp"
            "ini"
            "basher"
            "dockerfile"
            "gleam"
            "slint"
            "svelte"
            "dart"
            "flutter-snippets"
            "git-firefly"
            "terraform"
            "zig"
            "gdscript"
            "ruff"
            "haskell"
            "assembly"
            "ruby"
            "kdl"
            "just"

            # Themes
            "xcode-themes"
            "vscode-dark-plus"
            "macos-classic"
            "intellij-newui-theme"

            # Icon Themes
            "vscode-icons"
          ];
          # Avoid large lsps or the language toolset
          # As they should be provided by the dev shell
          # Ex: dart zsl haskell-language-server
          extraPackages = [
            pkgs.nixd
            pkgs.nil
            pkgs.rustfmt

            pkgs.rubyPackages.solargraph

            # For shell scripts
            pkgs.bash-language-server
            pkgs.shellcheck
          ];
          userSettings = {
            auto_update = false;
            terminal = {
              working_directory = "current_project_directory";
              detect_venv = "off";
            };
            icon_theme = "VSCode Icons for Zed (Dark)";
            theme = lib.mkForce "Colorizer";
            load_direnv = "shell_hook";
            base_keymap = "VSCode";
            show_whitespaces = "all";
            ui_font_size = lib.mkForce 14;
            buffer_font_size = lib.mkForce 14;
            indent_guides = {
              enabled = true;
              coloring = "indent_aware";
            };
            inlay_hints.enabled = true;
            auto_install_extensions = true;

            # Panels
            outline_panel.dock = "right";
            project_panel.dock = "right";

            buffer_font_family = lib.mkDefault "Fira Code";
            terminal.font_family = lib.mkDefault "Fira Code";
            format_on_save = "on";

            # title_bar = {
            #   show_onboarding_banner = false;
            #   show_project_items = false;
            #   show_user_menu = false;
            # };

            # tab_bar = {
            #   show = false;
            # };

            # toolbar = {
            #   quick_actions = false;
            # };

            # status_bar = {
            #   "experimental.show" = false;
            # };

            project_panel = {
              default_width = 400;
              hide_root = true;
              auto_fold_dirs = false;
              starts_open = false;
              scrollbar = {
                show = "never";
              };
              indent_guides = {
                show = "never";
              };
            };

            outline_panel = {
              default_width = 300;
              indent_guides = {
                show = "never";
              };
            };

            file_finder = {
              modal_max_width = "large";
            };

            node = {
              path = lib.getExe pkgs.nodejs;
              npm_path = lib.getExe' pkgs.nodejs "npm";
            };

            languages = {
              Nix = {
                language_servers = [
                  "nil"
                  "!nixd"
                ];
                formatter = {
                  external = {
                    command = lib.getExe pkgs.alejandra;
                  };
                };
              };

              Ruby = {
                language_servers = ["solargraph" "!rubocop" "!ruby-lsp"];
              };

              "Shell Script" = {
                format_on_save = "on";
                formatter = {
                  external = {
                    command = lib.getExe pkgs.shfmt;
                    arguments = ["--filename" "{buffer_path}" "--indent" "2"];
                  };
                };
                tab_size = 2;
              };

              Python = {
                language_servers = ["pyright" "ruff"];
                format_on_save = "on";
                formatter = {
                  language_server = {
                    name = "ruff";
                  };

                  # Doesn't work for some reason
                  /*
                  code_actions = {
                    "source.organizeImports.ruff" = true;
                  };
                  */
                };
              };

              /*
                Markdown = {
                formatter = "prettier";
              };
              TOML = {
                formatter = "taplo";
              };
              JSON = {
                formatter = "prettier";
              };
              */

              Zig = {
                format_on_save = "on";
                formatter = "language_server";
                code_actions_on_format = {
                  "source.fixAll" = true;
                  "source.organizeImports" = true;
                };
              };
            };

            # Setting this makes nix's formatter not work
            /*
              prettier = {
              allowed = true;
            };
            */

            lsp = {
              zls = {};

              dart = {
                settings = {
                  lineLength = 140;
                };
              };

              omnisharp = {
                binary.arguments = ["optional" "additional" "args" "-lsp"];
              };

              solargraph = {
                initialization_options = {
                  diagnostics = true;
                  formatting = true;
                };
                settings = {
                  use_bundler = false;
                };
              };

              pyright = {
                settings = {
                  "python.analysis" = {
                    diagnosticMode = "workspace";
                    typeCheckingMode = "strict";
                  };
                  python = {
                    pythonPath = ".venv/bin/python";
                  };
                };
              };

              hls = {
                initialization_options = {
                  haskell.formattingProvider = "fourmolu";
                };
              };

              rust-analyzer = {
                settings = {
                  diagnostics = {
                    enable = true;
                    styleLints = {
                      enable = true;
                    }; # Corrected styleLints access
                  };
                  checkOnSave = true;
                  check = {
                    command = "clippy";
                    features = "all";
                  };
                  cargo = {
                    buildScripts = {
                      enable = true;
                    }; # Corrected buildScripts access
                    features = "all";
                  };
                  inlayHints = {
                    bindingModeHints = {
                      enable = true;
                    }; # Corrected access
                    closureStyle = "rust_analyzer";
                    closureReturnTypeHints = {
                      enable = "always";
                    }; # Corrected access
                    discriminantHints = {
                      enable = "always";
                    }; # Corrected access
                    expressionAdjustmentHints = {
                      enable = "always";
                    }; # Corrected access
                    implicitDrops = {
                      enable = true;
                    };
                    lifetimeElisionHints = {
                      enable = "always";
                    }; # Corrected access
                    rangeExclusiveHints = {
                      enable = true;
                    };
                  };
                  procMacro = {
                    enable = true;
                  };
                  rustc = {
                    source = "discover";
                  };
                  files = {
                    excludeDirs = [
                      ".cargo"
                      ".direnv"
                      ".git"
                      "node_modules"
                      "target"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
