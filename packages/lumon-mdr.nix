{
  lib,
  stdenv,
  fetchgit,
  makeWrapper,
  cmake,
  gcc,
  libxkbcommon,
  libxinerama,
  libxt,
  libxtst,
  libxcb,
  libx11,
  libxrandr,
  libxxf86vm,
  libxcursor,
  glew,
  glfw3,
  libGLU,
  libGL,
}:
stdenv.mkDerivation {
  pname = "LumonMDR";
  version = "cba2489";

  src = fetchgit {
    url = "https://github.com/andrewchilicki/LumonMDR";
    rev = "cba248923f61d308c4db2cea9b6c78e3f63898f8";
    hash = "sha256-k5vbMvWg71cJWxbm+f7ORUz4zhwggt/SHmg/yVguQO8=";
  };

  dontUnpack = true;

  nativeBuildInputs = [
    cmake
    gcc
    makeWrapper
  ];

  buildInputs = [
    libGL
    libGLU
    glfw3
    glew
    libxkbcommon
    libxinerama
    libxt
    libxtst
    libxcb
    libx11
    libxrandr
    libxxf86vm
    libxcursor
  ];

  configurePhase = ''
    cmake -S $src -B .
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/share
    mkdir -p $out/bin

    cp -R $src/assets $out/share/
    cp LumonMDR $out/share/

    makeWrapper $out/share/LumonMDR $out/bin/LumonMDR \
      --run "
          mkdir -p \"\$HOME/.config/LumonMDR\";
          [ -d \"\$HOME/.config/LumonMDR/assets\" ] || {
              cp -R $out/share/assets \"\$HOME/.config/LumonMDR/assets\";
              chmod -R u+rwX,go+rX \"\$HOME/.config/LumonMDR/assets\";
          };
          cd \"\$HOME/.config/LumonMDR\"
      "
      # --chdir \$HOME/.config/LumonMDR # Doesn't work becuase it's wrapped within single quotes by makeWrapper

  '';

  meta = {
    homepage = "https://github.com/andrewchilicki/LumonMDR";
    description = "Lumon's Macrodata Refinement application inspired by Apple TV's 'Severance'. ";
    platforms = lib.platforms.linux;
  };
}
