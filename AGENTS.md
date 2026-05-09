# Agent Instructions for (Lunar Nix)

## Project Overview

Lunar Nix is a personal NixOS configuration using the **dendritic pattern** (inspired by [vic/den](https://github.com/vic/den)). It manages multiple hosts (laptops, desktops, servers) with a declarative, aspect-oriented approach.

---

## Step 1: Setup

First, check if the `den/` directory exists:

```bash
ls den/
```

If **not found**, clone it:

```bash
git clone https://github.com/vic/den.git den/
```

---

## Step 2: Read These Files First

1. **`README.md`** - Project overview
2. **`den/AGENTS_EXAMPLE.md`** - Dendritic pattern documentation (read this before touching any code!)

---

## Repository Structure

```
/etc/nixos/
├── flake.nix           # Main flake entry point
├── modules/
│   ├── defaults.nix    # Global defaults applied to all entities
│   ├── den.nix         # Creates "lunar" namespace from den
│   ├── hosts.nix       # Host declarations
│   ├── schema.nix      # Entity schema definitions
│   ├── outputs.nix     # Flake output generation
│   ├── hosts/          # Host-specific configurations
│   ├── lunar/          # Feature modules (aspects)
│   │   ├── plasma.nix  # KDE Plasma 6
│   │   ├── gaming.nix  # Steam, GameMode, PRIME offload
│   │   ├── dev.nix     # devenv, VSCode extensions
│   │   ├── audio.nix   # PipeWire configuration
│   │   ├── browsers.nix # Firefox, Zen Browser, Chromium
│   │   └── ...
│   └── users/
│       └── loystonpais/ # Primary user configuration
├── packages/           # Custom Nix packages
├── den/                # The den framework
└── secrets/            # SOPS-encrypted secrets
```

---

## Key Concepts

### Dendritic Pattern

The pattern uses **aspects** as the primary unit of organization. An aspect declares behavior per Nix class (`nixos`, `homeManager`, etc.):

```nix
lunar.plasma = mode: {
  nixos = { pkgs, ... }: { ... };
  homeManager = { pkgs, ... }: { ... };
  provides.some-feature = { ... };
};
```

### Parametric Dispatch

Functions use `builtins.functionArgs` introspection. They only activate when their required arguments are present:
- `{ host, ... }` matches any context with `host`
- `{ host, user }` only matches when both exist
- `{ home }` matches standalone home contexts only

### Context Pipeline

Host/User/Home declarations flow through `den.ctx` to resolve into fully applied Nix module inputs.

---

## Important Conventions

### Terminology: "Aspect" Not "Module"

This configuration uses the **dendritic pattern** where the primary unit of organization is called an **aspect** (not a module). Files in `modules/lunar/` are **aspects**, not modules. When referring to these, always use "aspect" (e.g., "the podman aspect", "add a new aspect").

### Commit Message Format

Use the format: `area: description`

- **area**: Can be:
  - An aspect name from `modules/lunar/` (e.g., `sops`, `ssh`, `secrets`, `vscode`, `audio`, `plasma`, `podman`, `browser`)
  - A hostname when changing code in `modules/hosts/<hostname>`
  - `lunar:` or `flake:` for changes to the flake in general
  - Combined with more context when needed (e.g., `modules: android:`)

Examples from this project:
```
sops: add useful packages
ssh: fix ssh on some terms
secrets: add new pub key
vscode: add AI extensions
flake: add cache priority
roglaptop: enable cuda
lunar: add AGENT.md and README.md
```

Rules:
- Use lowercase for area and description
- No period at the end
- Keep it to one line
- Use imperative mood ("add", "fix", "update", "remove" not "added", "fixed")

### Lunar Namespace

Features are defined in `modules/lunar/` and automatically available as `lunar.<feature>` through the `den.namespace` mechanism in `modules/den.nix`.

### Host Configurations

```nix
den.aspects.myhost = {
  includes = [ den.aspects.myuser ];
  nixos = { ... }: { ... };
  homeManager = { ... }: { ... };
};
```

### User Configurations

```nix
den.aspects.loystonpais = {
  includes = [
    den.provides.primary-user
    (den.provides.user-shell "zsh")
  ];
  nixos = { pkgs, ... }: { ... };
  homeManager = { pkgs, ... }: { ... };
};
```

### Underscore-prefixed Directories

Directories and files starting with `_` (e.g., `_hw/`, `_vfio/`, `_services/`, `_infect/`) are **not auto-imported**. They are intentionally kept outside the dendritic pattern:

- Either because it doesn't make sense to convert them yet
- Or the conversion is work in progress

These need to be explicitly imported where needed.

---

## Feature Highlights

- **Desktop**: KDE Plasma 6 with WhiteSur theme
- **Gaming**: Steam, Heroic, PrismLauncher, MangoHUD, GameMode, NVIDIA PRIME offload
- **Development**: devenv, VSCode (60+ extensions), Godot, Blender
- **Containers**: Podman, Distrobox, Flatpak
- **Virtualization**: Libvirt/QEMU, KVMFR (Looking Glass), Waydroid
- **Browsers**: Firefox, Zen Browser, Chromium (Brave)
- **Audio**: PipeWire with ALSA, Pulse, Jack support
- **Shell**: xonsh (primary), zsh, bash with Starship prompt
- **Secrets**: SOPS with age encryption
- **Remote Deploy**: Tailscale SSH, nixos-rebuild over SSH

---

## Key Files for Reference

| File | Purpose |
|------|---------|
| `flake.nix` | Main flake entry point |
| `modules/defaults.nix` | Global defaults (mutual providers, nixpkgs config) |
| `modules/den.nix` | Lunar namespace creation |
| `modules/schema.nix` | Schema base modules |
| `modules/users/loystonpais/loystonpais.nix` | Primary user configuration |
| `den/nix/lib/parametric.nix` | Parametric dispatch logic |
| `den/modules/options.nix` | `den.hosts`, `den.homes`, `den.schema` options |

---

## CI/CD

- **Cachix**: Pushes built packages to `loystonpais.cachix.org`
- **Remote Rebuild**: Uses Tailscale to deploy to remote hosts

---

## Agent Workflow & Tips

- **Referencing Files**: To reference local files (assets, icons, configs, etc.) within Nix modules, always use `${inputs.self.outPath}/path/to/file` to ensure they are correctly resolved relative to the flake root.
- **Agent Orchestration**: For running multiple agents simultaneously, use `git worktree` to create isolated environments. Creating worktrees within a project subdirectory (e.g., `.agent-worktrees/`) allows a primary agent to orchestrate and monitor sub-agents effectively. Remember to add the worktree directory to `.gitignore`.
- **Pre-commit Hooks**: If a commit fails due to missing or broken pre-commit hooks (e.g., `.git/hooks/pre-commit`), use `git commit --no-verify` to proceed. When doing so, append `(no-verify)` to the commit message.
- **Git Workflow for Agents**:
  - **Commit After Feature**: Always commit changes immediately after completing a feature.
  - **Commit Before Starting**: Before starting a new feature, check for and commit any uncommitted changes to ensure a clean slate.
  - **Commit Messages**: Use a descriptive commit message for small, clear changes. For large or complex changes where a precise message is difficult, commit all files with a message prefixed with `stash:` (e.g., `stash: sync uncommitted changes`). Note: Since agents in worktrees are task-specific, these "stash" commits serve as checkpoints.

---

## DO NOT MODIFY

- `den/` directory (submodule, update via git)
- `flake.lock` (auto-generated)
