{den, ...}: {
  lunar.git = {
    homeManager = {...}: {
      programs.git.enable = true;
      programs.git.lfs.enable = true;
    };
  };
}
