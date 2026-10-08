{
  rustPlatform,
  fetchFromGitHub,
  lib,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "spotify-adblock";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "abba23";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-UzpHAHpQx2MlmBNKm2turjeVmgp5zXKWm3nZbEo0mYE=";
  };

  postPatch = ''
    substituteInPlace src/lib.rs \
    --replace-fail \
    'PathBuf::from("/etc/spotify-adblock/config.toml"),' \
    'PathBuf::from("/etc/spotify-adblock/config.toml"), PathBuf::from("'$out'/etc/spotify-adblock/config.toml"),'
  '';

  configUrl = "https://raw.githubusercontent.com/${src.owner}/${src.repo}/main/config.toml";

  cargoHash = "sha256-oGpe+kBf6kBboyx/YfbQBt1vvjtXd1n2pOH6FNcbF8M=";

  doCheck = false;

  postInstall = ''
    mkdir -p $out/etc/spotify-adblock
    cp config.toml $out/etc/spotify-adblock
  '';

  meta = with lib; {
    description = "Adblocker for Spotify";
    homepage = "https://github.com/abba23/spotify-adblock";
    license = licenses.unlicense;
    maintainers = [];
  };
}
