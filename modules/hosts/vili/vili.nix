{
  den,
  lunar,
  lib,
  inputs,
  ...
}: {
  den.aspects.vili = {
    includes = [
      den.aspects.loystonpais

      # import necessary modules
      {
        nixos = {
          imports = [
            inputs.droidspaces.nixosModules.working-droidspaces-rootfs-minimal
            inputs.droidspaces.nixosModules.pin-systemd-v257
          ];
        };
      }

      # Simplify setting wlan0
      {
        nixos = {pkgs, ...}: let
          wlan0 = pkgs.writeShellScriptBin "wlan0" ''
            set -e

            case "$1" in
              monitor)
                ip link set wlan0 down
                echo 4 | sudo tee /sys/module/wlan/parameters/con_mode > /dev/null
                ip link set wlan0 up
                echo "Monitor mode enabled"
                ;;
              managed)
                ip link set wlan0 down
                echo 0 | sudo tee /sys/module/wlan/parameters/con_mode > /dev/null
                ip link set wlan0 up
                echo "Managed mode enabled"
                ;;
              toggle)
                mode=$(cat /sys/module/wlan/parameters/con_mode)
                if [ "$mode" = "4" ]; then
                  $0 managed
                else
                  $0 monitor
                fi
                ;;
              status)
                mode=$(cat /sys/module/wlan/parameters/con_mode)
                case "$mode" in
                  0) echo "managed" ;;
                  4) echo "monitor" ;;
                  *) echo "($mode)" ;;
                esac
                ;;
              *)
                echo "Usage: wlan0 [monitor|managed|toggle|status]" >&2
                exit 1
                ;;
            esac
          '';
        in {
          environment.systemPackages = [
            wlan0
          ];
        };
      }

      # Set a static ip for wlan0
      {
        nixos = {pkgs, ...}: {
          systemd.services.wlan0-static-ip = {
            description = "Add static IP to wlan0";
            after = ["network-pre.target"];
            before = ["network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "-${pkgs.iproute2}/bin/ip address add 192.168.55.1/24 dev wlan0";
            };
          };
        };
      }
    ];

    nixos = {
      pkgs,
      lib,
      config,
      modulesPath,
      ...
    }: {
      imports = [
        "${modulesPath}/virtualisation/lxc-container.nix"

        # Adapted from https://github.com/shuuri-labs/nixos-rp5/blob/e37a7c96b9bcd0cd093c0c4498f9070d00569ba5/modules/graphics/mesa-turnip.nix
        {
          # Graphics/OpenGL
          hardware.graphics = {
            enable = true;

            extraPackages = with pkgs; [
              # Mesa with Freedreno/Turnip
              mesa

              # Vulkan
              vulkan-loader
              vulkan-tools
              vulkan-validation-layers
              vulkan-extension-layer

              # VA-API (video acceleration)
              # Note: VA-API on Adreno may have limited support
            ];
          };

          # Environment variables for Turnip/Freedreno
          environment.variables = {
            # Vulkan ICD (Installable Client Driver)
            VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/freedreno_icd.aarch64.json";

            # Mesa settings for better compatibility
            MESA_VK_WSI_PRESENT_MODE = "fifo"; # VSync mode

            # Debug options (uncomment for troubleshooting)
            # TU_DEBUG = "startup";  # Turnip debug output
            # MESA_DEBUG = "1";
            # LIBGL_DEBUG = "verbose";

            # Force Turnip as the Vulkan driver
            # AMD_VULKAN_ICD = "RADV";  # Not applicable, but shows pattern

            # OpenGL ES settings
            MESA_GLES_VERSION_OVERRIDE = "3.2";
            MESA_GLSL_VERSION_OVERRIDE = "320";

            MESA_LOADER_DRIVER_OVERRIDE = "kgsl";
            __GL_THREADED_OPTIMIZATIONS = "1";
          };

          # Vulkan layers configuration
          environment.etc."vulkan/explicit_layer.d/VkLayer_khronos_validation.json".source = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d/VkLayer_khronos_validation.json";

          # Graphics packages
          environment.systemPackages = with pkgs; [
            # Vulkan tools
            vulkan-tools # vulkaninfo, vkcube
            vulkan-caps-viewer # GUI Vulkan info (if desktop available)

            mesa-demos # glxgears, es2gears, etc.

            # GPU monitoring (if available for ARM)
            # radeontop  # AMD only
            # nvtop      # NVIDIA/AMD/Intel

            # Debug tools
            apitrace # OpenGL/Vulkan call tracing
          ];

          # DRM (Direct Rendering Manager) configuration
          services.udev.extraRules = ''
            # Allow video group access to GPU devices
            SUBSYSTEM=="drm", KERNEL=="card*", MODE="0666", GROUP="video"
            SUBSYSTEM=="drm", KERNEL=="renderD*", MODE="0666", GROUP="video"

            # Qualcomm KGSL (GPU) device
            SUBSYSTEM=="kgsl", MODE="0666", GROUP="video"
            KERNEL=="kgsl-3d0", MODE="0666", GROUP="video"

            SUBSYSTEM=="misc", KERNEL=="ion", MODE="0666", GROUP="video"
          '';

          #* Temporary fix since udevd doesn't run within containers
          systemd.services.fix-gpu-permissions = {
            enable = config.boot.isContainer;
            description = "Fix GPU-related device permissions";
            wantedBy = ["multi-user.target"];
            after = ["local-fs.target"];

            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "fix-device-perms" ''
                # Wait a bit for devices to appear
                for i in $(seq 1 15); do
                  found=0

                  # /dev/ion
                  if [ -e /dev/ion ]; then
                    chown root:video /dev/ion
                    chmod 0666 /dev/ion
                    found=1
                  fi

                  # DRM devices
                  for dev in /dev/dri/card* /dev/dri/renderD*; do
                    if [ -e "$dev" ]; then
                      chown root:video "$dev"
                      chmod 0666 "$dev"
                      found=1
                    fi
                  done

                  # KGSL (Qualcomm GPU)
                  if [ -e /dev/kgsl-3d0 ]; then
                    chown root:video /dev/kgsl-3d0
                    chmod 0666 /dev/kgsl-3d0
                    found=1
                  fi

                  # Exit early if at least one device was handled
                  [ "$found" = 1 ] && exit 0

                  sleep 1
                done

                echo "No GPU devices found" >&2
                exit 1
              '';
            };
          };

          # Ensure gamer is in video group
          users.users.loystonpais.extraGroups = ["video" "render"];
        }
      ];

      system.stateVersion = "26.05";
    };
  };
}
