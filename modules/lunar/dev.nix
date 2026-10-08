{den, ...}: {
  lunar.dev = {
    nixos = {
      pkgs,
      lib,
      ...
    }: {
      config = lib.mkMerge [
        {
          programs.direnv = {
            enable = true;
            enableXonshIntegration = true;
            enableBashIntegration = true;
            enableZshIntegration = true;
          };
        }
      ];
    };

    homeManager = {
      config,
      options,
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [
        devenv
        fzf
      ];

      home.shell.enableShellIntegration = true;

      programs.starship =
        {
          enable = true;

          enableBashIntegration = true;
          enableZshIntegration = true;

          settings = {
            shell = {
              xonsh_indicator = "X";
              bash_indicator = "B";
              zsh_indicator = "Z";
              nu_indicator = "N";
              unknown_indicator = "?";
              format = "[$indicator]($style)";
              disabled = false;
            };

            shlvl = {
              format = "[$symbol]($style) ";
              repeat = true;
              symbol = "❯";
              repeat_offset = 1;
              threshold = 0;
              disabled = false;
            };

            status = {
              disabled = false;
            };
          };
        }
        // lib.optionalAttrs (options.programs.starship ? enableXonshIntegration) {
          enableXonshIntegration = true;
        };

      programs.zoxide =
        {
          enable = true;

          enableBashIntegration = true;
          enableZshIntegration = true;
        }
        // lib.optionalAttrs (options.programs.zoxide ? enableXonshIntegration) {
          enableXonshIntegration = true;
        };

      programs.bash.enable = true;

      programs.zsh = {
        enable = true;
        dotDir = config.home.homeDirectory;
        enableCompletion = true;
        enableVteIntegration = true;
        autocd = true;
        syntaxHighlighting.enable = true;
        autosuggestion = {
          enable = true;
          strategy = ["history" "completion"];
          highlight = "fg=244";
        };

        historySubstringSearch.enable = true;

        initContent = ''
          # Completion styling
          zstyle ':completion:*' menu select                        # arrow-key menu selection
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive matching
          zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"  # colored completions
          zstyle ':completion:*' group-name '''                      # group results by category
          zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
          zstyle ':completion:*:messages'     format '%F{purple}-- %d --%f'
          zstyle ':completion:*:warnings'     format '%F{red}-- no matches --%f'
          zstyle ':completion:*' squeeze-slashes true
          zstyle ':completion:*' complete-options true

          # Keybinds: shift-tab to reverse through menu
          bindkey '^[[Z' reverse-menu-complete

          eval "$(${lib.getExe pkgs.fzf} --zsh)"
        '';

        history = {
          size = 10000000;
          save = 10000000;
          ignoreSpace = true;
          ignoreDups = true;
          ignoreAllDups = true;
          expireDuplicatesFirst = true;
          extended = true;
          share = true;
          append = true;
          path = "${config.home.homeDirectory}/.zsh_history";
        };
      };
    };
  };
}
