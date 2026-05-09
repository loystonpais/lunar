# Agent Instructions for Lunar Nix

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

## Step 2: Essential Reading

1. **`README.md`**: Project overview and basic setup.
2. **`den/AGENTS_EXAMPLE.md`**: Detailed documentation on the dendritic pattern (read this before modifying any code!).

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
│   ├── lunar/          # Feature aspects
│   │   ├── plasma.nix  # KDE Plasma 6
│   │   ├── gaming.nix  # Steam, GameMode, PRIME offload
│   │   ├── dev.nix     # Development environment
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
The primary unit of organization is the **aspect**. An aspect declares behavior across multiple Nix classes (`nixos`, `homeManager`, etc.):

```nix
lunar.plasma = mode: {
  nixos = { pkgs, ... }: { ... };
  homeManager = { pkgs, ... }: { ... };
  provides.some-feature = { ... };
};
```

### Parametric Dispatch
Logic is activated via `builtins.functionArgs` introspection. Aspects only trigger when their required arguments are supplied:
- `{ host, ... }`: Matches any context containing a `host`.
- `{ host, user }`: Matches only when both `host` and `user` are present.
- `{ home }`: Matches standalone Home Manager contexts.

---

## Important Conventions

### Terminology: "Aspect" Not "Module"
Always refer to files in `modules/lunar/` as **aspects**. The term "module" is reserved for standard NixOS/Home Manager modules.

### Commit Message Format
Format: `area: description`

- **area**: The aspect name, hostname, or general category (e.g., `sops`, `roglaptop`, `lunar`, `flake`).
- **Rules**: Lowercase, no trailing period, imperative mood (e.g., `fix:`, `add:`).

### Underscore-prefixed Directories
Directories starting with `_` (e.g., `_hw/`, `_services/`) are **not auto-imported**. They must be explicitly imported where needed.

---

## Agent Workflow & Guidelines

### Referencing Files
To reference local files (assets, icons, configs) within Nix modules, use `${inputs.self.outPath}/path/to/file`. This ensures the path is correctly resolved relative to the flake root.

### Git Workflow
- **Commit Before Starting**: Before beginning a feature, commit any uncommitted changes.
- **Commit After Feature**: Commit immediately upon completing a task or feature.
- **Commit Messages**: 
    - Use descriptive messages for standard changes.
    - Use `stash: <description>` for large checkpoints where a precise message is difficult.
- **Pre-commit Hooks**: If a commit fails due to broken hooks, use `git commit --no-verify` and append `(no-verify)` to the message.

---

## Sub-Agent Orchestration & Communication

### Roles & Identification
- **Orchestrator (Main Agent)**: Runs in the project root (**Pane 0** of a TMUX session).
- **Sub-Agent**: Task-specific agents running in isolated worktrees under `.agent-worktrees/`.

### Worktree Management
- The Main Agent creates worktrees in `.agent-worktrees/<feature-name>`.
- Branches MUST be namespaced as `agents/<feature-name>`.
- **Setup**: The Main Agent MUST create the worktree and initialize the FIFO pipes (`pipe-in`, `pipe-out`) using `mkfifo` before spawning a sub-agent.

### Scopes & Execution
- **AGENT_SCOPE**: Check the `AGENT_SCOPE` env var (values: `500` or `800`).
- **CLI Commands**: `agent-<scope>-<cli>` (e.g., `agent-500-gemini`).
- **Sandboxing**: All agents are `bwrap`-sandboxed and cannot write outside their execution directory.

### TMUX Communication Protocol (Hub-and-Spoke)
- **Constraint**: The Main Agent MUST run inside TMUX. If not, inform the user and abort.
- **Mechanism**: 
    1. **Signal**: A sub-agent writes a message to its `pipe-in` and notifies the Main Agent:
       `tmux send-keys -t 0 "Subagent <N>: <short-summary>" Enter`
    2. **Read**: The Main Agent reads from the sub-agent's `pipe-in`.
    3. **Respond**: The Main Agent writes to the sub-agent's `pipe-out` and signals back via `tmux send-keys`.

---

## DO NOT MODIFY

- `den/` directory (external submodule)
- `flake.lock` (auto-generated)
