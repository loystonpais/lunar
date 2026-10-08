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
    ...
  }: {
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
          };

        basePermissions = c:
          with c; [
            (unsafe-add-raw-args "--ro-bind / /")
            (unsafe-add-raw-args "--bind /proc /proc")
            (unsafe-add-raw-args "--dev /dev") # a new /dev removes access to drives
            (unsafe-add-raw-args "--bind /tmp /tmp") # /tmp needn't be tmpfs always
            (unsafe-add-raw-args "--bind /run /run")
            (unsafe-add-raw-args "--ro-bind /nix /nix") # important
            (unsafe-add-raw-args "--bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket") # nix will connect to the daemon

            (unsafe-add-raw-args "--ro-bind ~ ~") # Make home ro

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

            (try-readwrite (noescape "~/.local/state/nix"))
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
            (try-readwrite (noescape "~/.local/state/blesh"))

            (try-readwrite (noescape "~/.local/share/rtk"))

            (try-readwrite (noescape "~/.local/share/zoxide"))
            # TODO: add more rw paths

            # Bind some paths from agent home to real home like .gemini
            (bind-agent-home-to-home ".gemini")
            (bind-agent-home-to-home ".claude")
            (bind-agent-home-to-home ".codex")
            (bind-agent-home-to-home ".pi")
            (bind-agent-home-to-home ".antigravitycli")

            (bind-agent-home-to-home ".config/opencode")
            (bind-agent-home-to-home ".local/share/opencode")
            (bind-agent-home-to-home ".local/state/opencode")
            #

            # Keep these global, like mcp configs etc..
            (bind-home ".gemini/config")

            (bind-skills-to-global-skills ".gemini/skills")

            (fwd-env "PATH") # forward paths from outside

            (set-env "AGENT_SCOPE" scope)

            mount-cwd
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
