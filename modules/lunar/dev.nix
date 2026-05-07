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

          environment.systemPackages = with pkgs; [
            devenv
          ];
        }
      ];
    };

    homeManager = {config, ...}: {
      home.shell.enableShellIntegration = true;

      programs.starship = {
        enable = true;

        enableXonshIntegration = true;
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

          custom.tmux = {
            command = "echo tmux";
            when = ''test "$TMUX"'';
            format = "[$symbol]($style) ";
            symbol = "🪟 ";
            style = "bold blue";
          };
        };
      };

      programs.zoxide = {
        enable = true;

        enableBashIntegration = true;
        enableXonshIntegration = true;
        enableZshIntegration = true;
      };

      programs.bash.enable = true;

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autocd = true;
        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;

        history = {
          size = 10000000;
          save = 10000000;
          ignoreSpace = true;
          ignoreDups = true;
          ignoreAllDups = true;
          expireDuplicatesFirst = true;
          extended = true;
          share = true;
          path = "${config.home.homeDirectory}/.zsh_history";
        };
      };
    };
  };
}
