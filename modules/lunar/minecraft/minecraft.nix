{
  den,
  inputs,
  ...
}: {
  lunar.minecraft = {
    nixos = {
      pkgs,
      lib,
      ...
    }: {
      config = lib.mkMerge [
        {
          # Accessible from /etc/java-collection/
          # Example: /etc/java-collection/jdk17/bin/java
          environment.etc."java-collection/jdk17".source = pkgs.jdk17;
          environment.etc."java-collection/jdk21".source = pkgs.jdk21;
          environment.etc."java-collection/jdk25".source = pkgs.jdk25;

          environment.etc."glfw-collection/glfw3".source = pkgs.glfw3;
          environment.etc."glfw-collection/glfw3-waywall".source = inputs.self.packages.${pkgs.system}.glfw3-waywall;

          environment.systemPackages = with pkgs; [
            # prismlauncher # Installed via profile for now

            waywall

            inputs.self.packages.${pkgs.system}.ninjabrainbot
            inputs.self.packages.${pkgs.system}.zig-seed-glitchless
          ];
        }
      ];
    };

    homeManager = {config, ...}: {
      home.file.".config/waywall".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/lunar/minecraft/waywall";
    };

    provides.nixcraft = {
      nixos = {...}: {
        imports = [
          inputs.nixcraft.nixosModules.default
        ];

        config = {
          nixcraft = {
            enable = true;
            cache.enable = true;
            renice.enable = true;
          };
        };
      };

      homeManager = {
        config,
        pkgs,
        lib,
        ...
      }: let
        speedrunpack-mrpack = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/1uJaMUOm/versions/5icZYG8d/SpeedrunPack-mc1.16.1-v6.0.0.mrpack";
          hash = "sha256-5cLBucJTaia7tTytrJrUA5Rou/oyLot1umWq/4o+Fuw=";
        };

        fsgmod-jar = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/XZOGBIpM/versions/4IW4nMP3/fsg-mod-5.2.0%2BMC1.16.1.jar";
          hash = "sha256-bA3Y+7OWex8LwEXgMN+7DH6vi6hIoOZ7w3XzA3AE4qg=";
        };

        # A world dir
        mcsr-practice-map = pkgs.fetchzip {
          url = "https://github.com/Dibedy/The-MCSR-Practice-Map/releases/download/1.0.1/MCSR.Practice.v1.0.1.zip";
          stripRoot = false;
          hash = "sha256-ukedZCk6T+KyWqEtFNP1soAQSFSSzsbJKB3mU3kTbqA=";
        };
      in {
        imports = [
          inputs.nixcraft.homeModules.default
        ];

        config = {
          nixcraft = {
            server.instances = {};

            enable = true;

            client = {
              # Online account uuid. this will be set to NIXCRAFT_CLIENT_AUTH_UUID env var
              # auth.uuid = "bda81d24e88249ee86585800903d8c35";

              # Config to share with all instances
              shared = {
                # Symlink screenshots dir from all instances
                files."screenshots".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Pictures";

                # Enable online account
                account = {
                  offline = false;
                  # If uuid is not provided here, the auth script will pick it up
                  # from NIXCRAFT_CLIENT_AUTH_UUID env var
                  # If the env var is not set then script will always prompt for login
                  uuid = "bda81d24e88249ee86585800903d8c35";
                };

                # enable external assets to download assets at runtime
                # instead of via nix
                # this has the added benefit of caching assets from PrismLauncher if present. Also no asset hash required.
                enableExternalAssets = true;

                # Game is passed to the gpu (set if you have nvidia gpu)
                enableNvidiaOffload = true;

                runtimeLibs = with pkgs; [
                  libdecor
                  cairo
                  gtk3
                  pango
                  glib
                  wayland
                  libxkbcommon
                ];

                envVars = {
                  # Fixes bug with nvidia
                  __GL_THREADED_OPTIMIZATIONS = "0";
                  LIBDECOR_PLUGIN_DIR = "${pkgs.libdecor}/lib/libdecor/plugins-1";
                };

                binEntry.enable = true;
              };

              instances = {
                # Example client customized for minecraft speedrunning
                fsg = {
                  # enable = true;

                  preLaunchShellScript = lib.mkBefore ''
                    mkdir -p ${lib.escapeShellArg config.nixcraft.client.instances.fsg.absoluteDir}
                    rm -rf ${lib.escapeShellArg config.nixcraft.client.instances.fsg.absoluteDir}/saves/*
                  '';

                  renice.enable = true;

                  # this advanced option accepts common arguments that are passed to the client
                  _classSettings = {
                    fullscreen = true;
                    uuid = "2909ee95-d459-40c4-bcbb-65a0cc413110";
                    username = "loystonlive";
                  };

                  mrpack = {
                    enable = true;
                    file = speedrunpack-mrpack;
                  };

                  # Set saves
                  saves = {
                    "Practice Map" = mcsr-practice-map;
                  };

                  # place custom files
                  files = {
                    # mods can also be manually set
                    "mods/fsg-mod.jar".source = fsgmod-jar;

                    # setting config files
                    "config/mcsr/standardsettings.json".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/lunar/minecraft/standardsettings.json";
                    "options.txt" = {
                      source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/lunar/minecraft/options.txt";
                    };
                  };

                  java = {
                    extraArguments = [
                      "-XX:+UseZGC"
                      "-XX:-ZUncommit"
                      "-XX:+AlwaysPreTouch"
                      "-Dgraal.TuneInlinerExploration=1"
                      "-XX:NmethodSweepActivity=1"
                    ];
                    # override java package. This mrpack needs java 17
                    package = pkgs.graalvmPackages.graalvm-oracle_17;
                    # set memory in MBs
                    maxMemory = 3500;
                    minMemory = 3500;
                  };

                  envVars.LD_PRELOAD = lib.mkBefore ["${pkgs.jemalloc}/lib/libjemalloc.so"];

                  # waywall can be enabled
                  waywall.enable = true;

                  lwjgl.version = "3.3.3";

                  # Add executable to path
                  binEntry = {
                    enable = true;
                    # Set executable name
                    name = "fsg";
                  };

                  desktopEntry = {
                    enable = true;
                    name = "Nixcraft FSG";
                    extraConfig = {
                      terminal = true;
                    };
                  };

                  assetHash = "sha256-VK8fwyG8j2FpKPXIZLVYofq5Kdl83hiW47S+xCE3qjQ=";
                };

                test-client = {};

                ranked = {
                  # enable = true;

                  # mrpack = {
                  #   enable = true;
                  #   file = pkgs.fetchurl {
                  #     url = "https://cdn.modrinth.com/data/I9W1u5Ac/versions/wvlNsT7L/mcsrranked-5.8.18.jar";
                  #     hash = "sha256-/O0XBhceTz/qsRgmJFiriDjVnCKY0+Fi8lVPU+3jsS0=";
                  #   };
                  # };

                  files = {
                    "config/mcsr/standardsettings.json".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/lunar/minecraft/standardsettings.json";
                    "options.txt" = {
                      source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/lunar/minecraft/options.txt";
                    };
                  };

                  java = {
                    extraArguments = [
                      "-XX:+UseZGC"
                      "-XX:-ZUncommit"
                      "-XX:+AlwaysPreTouch"
                      "-Dgraal.TuneInlinerExploration=1"
                      "-XX:NmethodSweepActivity=1"
                    ];
                    # override java package. This mrpack needs java 17
                    package = pkgs.graalvmPackages.graalvm-oracle_17;
                    # set memory in MBs
                    maxMemory = 3500;
                    minMemory = 3500;
                  };

                  envVars.LD_PRELOAD = lib.mkBefore ["${pkgs.jemalloc}/lib/libjemalloc.so"];

                  # waywall can be enabled
                  waywall.enable = true;

                  # Add executable to path
                  binEntry = {
                    enable = true;
                    # Set executable name
                    name = "ranked";
                  };

                  desktopEntry = {
                    enable = true;
                    name = "Nixcraft Ranked";
                    extraConfig = {
                      terminal = true;
                    };
                  };
                };

                rsg = {
                  # enable = true;

                  _classSettings = {
                    fullscreen = true;
                    uuid = "2909ee95-d459-40c4-bcbb-65a0cc413110";
                    username = "loystonlive";
                  };

                  mrpack = {
                    enable = true;
                    file = speedrunpack-mrpack;
                  };

                  # place custom files
                  files = {
                    # setting config files
                    "config/mcsr/standardsettings.json".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/lunar/minecraft/standardsettings.json";
                    "options.txt" = {
                      source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/lunar/minecraft/options.txt";
                    };
                  };

                  java = {
                    extraArguments = [
                      "-XX:+UseZGC"
                      "-XX:+AlwaysPreTouch"
                      "-Dgraal.TuneInlinerExploration=1"
                      "-XX:NmethodSweepActivity=1"
                    ];
                    package = pkgs.jdk17;
                    maxMemory = 4000;
                    minMemory = 4000;
                  };

                  waywall.enable = true;

                  binEntry = {
                    enable = true;
                    name = "rsg";
                  };

                  desktopEntry = {
                    enable = true;
                    name = "Nixcraft RSG";
                    extraConfig = {
                      terminal = true;
                    };
                  };

                  assetHash = "sha256-VK8fwyG8j2FpKPXIZLVYofq5Kdl83hiW47S+xCE3qjQ=";
                };
              };
            };
          };
        };
      };
    };
  };
}
