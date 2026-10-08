{
  den,
  inputs,
  ...
}: {
  lunar.fonts = {
    homeManager = {pkgs, ...}: {
      fonts.fontconfig.enable = true;

      home.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        nerd-fonts.symbols-only
        fira-code
        fira-code-symbols
      ];

      home.file = {
        ".local/share/fonts/InterVariable.ttf".source = "${inputs.self.outPath}/assets/fonts/InterVariable.ttf";
      };

      programs.vscode.profiles.default.userSettings = {
        "terminal.integrated.fontFamily" = "'Fira Code', 'Symbols Nerd Font'";
      };
    };
  };
}
