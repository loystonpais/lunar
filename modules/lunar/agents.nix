{
  den,
  lib,
  inputs,
  ...
}: let
  agentJailLib = {
    pkgs,
    jail-nix,
    agentDirPath,
    homesPath ? "${agentDirPath}/home",
    globalSkillsPath ? "${agentDirPath}/skills",
    rootOverlayPath ? "${agentDirPath}/root-overlay",
    ...
  }: let
    # Build a standard FHS rootfs containing essential runtimes & libraries for MCP servers
    agentFhs = pkgs.buildFHSEnv {
      name = "agent-mcp-fhs";
      targetPkgs = pkgs:
        with pkgs; [
          # Core binaries & shell
          glibc
          gcc.cc.lib
          bashInteractive
          coreutils
          findutils
          gnugrep
          gnused
          gawk

          # Common MCP / script runtimes
          nodejs_22
          python3
          uv
          bun

          # CLI utilities
          git
          curl
          jq

          # Common native libraries for unpatched / node-gyp / wheel binaries
          zlib
          openssl
          icu
        ];
    };
    fhsRoot = agentFhs.fhsenv;
  in {
    # jailed :: String -> AttrSet -> Derivation
    # scope   -
    # extraPerms - additional combinators beyond the agent base
    jailed = scope: pkg: {
      name ? "agent-${scope}-${pkg.meta.mainProgram}",
      extraPerms ? (_: []),
    }: let
      agentHome = "${homesPath}/${scope}";

      jail = jail-nix.lib.extend {
        inherit pkgs;

        additionalCombinators = c:
          with c; {
            bind-agent-home-to-home = path:
              compose [
                (add-runtime ''
                  mkdir -p ~/${escape path}
                  mkdir -p ${agentHome}/${escape path}
                '')
                (unsafe-add-raw-args "--bind ${agentHome}/${escape path} ~/${escape path}")
              ];
            try-bind-agent-home-to-home = path:
              compose [
                (add-runtime ''
                  mkdir -p ~/${escape path}
                  mkdir -p ${agentHome}/${escape path}
                '')
                (unsafe-add-raw-args "--bind-try ${agentHome}/${escape path} ~/${escape path}")
              ];

            bind-home = path:
              compose [
                (add-runtime ''
                  mkdir -p ~/${escape path}
                  mkdir -p ${agentHome}/${escape path}
                '')
                (unsafe-add-raw-args "--bind ~/${escape path} ~/${escape path}")
              ];

            bind-skills-to-global-skills = path:
              compose [
                (add-runtime ''
                  mkdir -p ~/${escape path}
                  mkdir -p ${escape globalSkillsPath}
                '')
                (readwrite globalSkillsPath)
                (unsafe-add-raw-args "--bind ${escape globalSkillsPath} ~/${escape path}")
              ];

            bind-agent-home-file-to-home-file = file:
              compose [
                (add-runtime ''
                  mkdir -p "$(dirname ~/${escape file})"
                  mkdir -p "$(dirname ${agentHome}/${escape file})"
                  [ ! -f ~/${escape file} ] && touch ~/${escape file}
                  [ ! -f ${agentHome}/${escape file} ] && touch ${agentHome}/${escape file}
                '')
                (unsafe-add-raw-args "--bind ${agentHome}/${escape file} ~/${escape file}")
              ];
          };

        basePermissions = c:
          with c; [
            (add-runtime ''
              mkdir -p "${rootOverlayPath}/upper"
              mkdir -p "${rootOverlayPath}/work"
            '')

            (unsafe-add-raw-args "--overlay-src ${fhsRoot}")
            (unsafe-add-raw-args "--overlay ${rootOverlayPath}/upper ${rootOverlayPath}/work /")

            (unsafe-add-raw-args "--ro-bind /nix /nix")
            (unsafe-add-raw-args "--bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket")
            (unsafe-add-raw-args "--ro-bind /etc /etc")
            (unsafe-add-raw-args "--bind /proc /proc")
            (unsafe-add-raw-args "--dev /dev")
            (unsafe-add-raw-args "--bind /tmp /tmp")
            (unsafe-add-raw-args "--bind /run /run")

            (unsafe-add-raw-args "--ro-bind-try /boot /boot")
            (unsafe-add-raw-args "--ro-bind-try /var /var")
            (unsafe-add-raw-args "--ro-bind-try /mnt /mnt")

            (readwrite rootOverlayPath)

            (unsafe-add-raw-args "--ro-bind ~ ~")

            (unsafe-add-raw-args "--share-net")
            (add-runtime ''
              RUNTIME_ARGS+=(--share-net)
            '')

            (unsafe-add-raw-args "--dev-bind-try /dev/dri /dev/dri")
            (unsafe-add-raw-args "--dev-bind-try /dev/nvidiactl /dev/nvidiactl")
            (unsafe-add-raw-args "--dev-bind-try /dev/nvidia-uvm /dev/nvidia-uvm")
            (unsafe-add-raw-args "--dev-bind-try /dev/nvidia0 /dev/nvidia0")

            # Mount the agent's home as rw
            (readwrite agentHome)

            # Ensure the dir exists at runtime before the jail starts
            (add-runtime ''
              mkdir -p "${agentHome}"
            '')

            # mount some paths in home as rw like cache, .cargo etc..
            (try-readwrite (noescape "~/.cargo"))

            (try-readwrite (noescape "~/.local/share/nix"))
            (try-readwrite (noescape "~/.config/nix"))

            (try-readwrite (noescape "~/.npm"))
            (try-readwrite (noescape "~/.cache"))
            (try-readwrite (noescape "~/.local/share/devenv"))
            (try-readwrite (noescape "~/.nix-defexpr"))

            (try-readwrite (noescape "~/.local/lib"))
            (try-readwrite (noescape "~/.local/bin"))
            (try-readwrite (noescape "~/.local/share/virtualenvs"))
            (try-readwrite (noescape "~/.cache/pip"))
            (try-readwrite (noescape "~/.cache/uv"))
            (try-readwrite (noescape "~/.local/share/uv"))
            (try-readwrite (noescape "~/.config/uv"))
            (try-readwrite (noescape "~/.pyenv"))
            (try-readwrite (noescape "~/.poetry"))
            (try-readwrite (noescape "~/.config/pypoetry"))

            (try-readwrite (noescape "~/.local/share/rtk"))

            (try-readwrite (noescape "~/.local/share/zoxide"))
            # TODO: add more rw paths

            # For antigravity-cli
            (try-readwrite (noescape "~/.gemini"))
            (bind-agent-home-file-to-home-file ".gemini/oauth_creds.json")
            (bind-agent-home-file-to-home-file ".gemini/google_accounts.json")
            (bind-agent-home-file-to-home-file ".gemini/antigravity-cli/antigravity-oauth-token")

            # Bind some paths from agent home to real home
            (bind-agent-home-to-home ".claude")
            (bind-agent-home-to-home ".codex")
            (bind-agent-home-to-home ".pi")

            (bind-agent-home-to-home ".config/opencode")
            (bind-agent-home-to-home ".local/share/opencode")

            # TODO: Look into this. Do we want scoped entire state dir?
            (bind-agent-home-to-home ".local/state")
            (try-readwrite (noescape "~/.local/state/nix"))

            (bind-skills-to-global-skills ".gemini/skills")

            # Prepend FHS binary paths to PATH at runtime, then forward PATH to container
            (add-runtime ''
              PATH="/usr/bin:/usr/sbin:$PATH"
            '')
            (fwd-env "PATH")

            (set-env "AGENT_SCOPE" scope)

            mount-cwd
            no-new-session
          ];
      };
    in
      jail name pkg (c: extraPerms c);
  };
in {
  lunar.agents = {
    provides.playwright = {
      nixos = {
        pkgs,
        inputs',
        ...
      }: let
        cloakbrowserChromium = inputs'.cloak-browser.packages.default;
      in {
        environment.systemPackages = with pkgs; [
          playwright
          playwright-mcp
          playwright-driver
          playwright-test

          cloakbrowserChromium
        ];

        environment.sessionVariables = {
          PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
          PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";

          CLOAKBROWSER_BINARY_PATH = "${cloakbrowserChromium}/bin/cloakbrowser-chrome";
        };
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        mcp-nixos
      ];
    };

    # TODO: Is there a better way to do this?
    provides.jailed = mkAgents: mkScopes: {extraPerms ? (_: [])}:
      lib.mkMerge [
        {
          homeManager.home.file."Agents/.directory".text = ''
            Agents Directory
          '';
        }

        {
          homeManager = {
            pkgs,
            lib,
            config,
            ...
          }: let
            inherit
              (agentJailLib {
                inherit pkgs;
                inherit (inputs) jail-nix;
                agentDirPath = "${config.home.homeDirectory}/Agents";
              })
              jailed
              ;

            agents = mkAgents pkgs;
            scopes = mkScopes;

            defaultAgentsPerms = {
              pi = c: [];
              opencode = c: [];
              claude = c: [];
            };
          in
            lib.mkMerge (
              lib.attrsets.mapCartesianProduct
              (
                {
                  agentName,
                  scopeName,
                }: let
                  agent = agents.${agentName};
                  scope = scopes.${scopeName};

                  agentPerms = agent.perms or (_: []);
                  scopePerms = scope.perms or (_: []);
                  defaultAgentPerms = defaultAgentsPerms.${agentName} or (c: []);
                in {
                  home.packages = [
                    (jailed scopeName agent.pkg {
                      extraPerms = c:
                        (agentPerms c)
                        ++ (scopePerms c)
                        ++ (defaultAgentPerms c)
                        ++ (with c; [
                          (add-runtime ''
                            PATH="$PATH:${lib.makeBinPath (builtins.catAttrs "pkg" (lib.attrValues agents))}"
                          '')
                        ]);
                    })
                  ];
                }
              )
              {
                agentName = builtins.attrNames agents;
                scopeName = builtins.attrNames scopes;
              }
            );
        }
      ];
  };
}
