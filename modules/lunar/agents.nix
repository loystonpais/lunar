{
  den,
  lib,
  inputs,
  ...
}: let
  agentJailLib = {
    pkgs,
    jail-nix,
    homesPath,
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
          };

        basePermissions = c:
          with c; [
            (unsafe-add-raw-args "--bind /proc /proc")
            (unsafe-add-raw-args "--dev /dev") # a new /dev removes access to drives
            (unsafe-add-raw-args "--bind /tmp /tmp") # /tmp needn't be tmpfs always
            (unsafe-add-raw-args "--bind /run /run")
            (unsafe-add-raw-args "--ro-bind /nix /nix") # important
            (unsafe-add-raw-args "--bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket") # nix will connect to the daemon

            (unsafe-add-raw-args "--ro-bind ~ ~") # Make home ro

            fake-passwd
            network

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
            (try-readwrite (noescape "~/.local/share/virtualenvs"))
            (try-readwrite (noescape "~/.cache/pip"))
            (try-readwrite (noescape "~/.cache/uv"))
            (try-readwrite (noescape "~/.local/share/uv"))
            (try-readwrite (noescape "~/.config/uv"))
            (try-readwrite (noescape "~/.pyenv"))
            (try-readwrite (noescape "~/.poetry"))
            (try-readwrite (noescape "~/.config/pypoetry"))

            (try-readwrite (noescape "~/.local/share/rtk"))
            # TODO: add more rw paths

            # Bind some paths from agent home to real home like .gemini
            (bind-agent-home-to-home ".gemini")
            (bind-agent-home-to-home ".claude")
            (bind-agent-home-to-home ".codex")

            (bind-agent-home-to-home ".config/opencode")
            (bind-agent-home-to-home ".local/share/opencode")
            (bind-agent-home-to-home ".local/state/opencode")
            #

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
                homesPath = "${config.home.homeDirectory}/Agents/home";
              })
              jailed
              ;

            agents = mkAgents pkgs;
            scopes = mkScopes;

            defaultAgentsPerms = {
              gemini = c: [];
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

    homeManager = {
      pkgs,
      jail,
      ...
    }: {
    };

    # provides.prompt-notify-via-zenity = lib.mkMerge [
    #   {
    #     homeManager = {pkgs, ...}: {
    #       home.packages = with pkgs; [zenity];
    #     };
    #   }

    #   (addTextToAllGlobalPromptFiles ''
    #     # Task Completion Notifications

    #     After completing every task, notify the user using `zenity`. Run the following command in the terminal as the final step:

    #     ```bash
    #     zenity --notification --text="<short summary of what was completed>"
    #     ```

    #     Examples:
    #     ```bash
    #     zenity --notification --text="Build complete"
    #     zenity --notification --text="Files refactored successfully"
    #     zenity --notification --text="Tests passed"
    #     zenity --notification --text="Dependency installation done"
    #     ```

    #     Keep the message short and specific to what was just done. Always run this as the last step, after all other work is finished.

    #   '')
    # ];
  };
}
