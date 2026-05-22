# Lunar Nix

<p align="center">
  <img src="assets/artwork/logo.svg" width="200" alt="Lunar Nix logo">
</p>

Personal NixOS configuration for a reliable, reproducible system. Uses [den](https://github.com/vic/den) for a declarative, aspect-oriented setup across multiple hosts.

## Overview

Lunar Nix is organized around **aspects**: independent feature units that apply to both NixOS and Home Manager. This ensures clean separation of concerns and easy configuration sharing.

- **Reproducible**: Built on Nix flakes for consistent deployments.
- **Aspect-Oriented**: Features are encapsulated in aspects under `modules/lunar/`.
- **Parametric Dispatch**: Configuration adapts automatically based on context (host, user, etc.).

## Screenshots

<p align="center">
  <img src="assets/screenshots/plasma1.png" width="800" alt="KDE Plasma 6 Desktop">
</p>

<p align="center">
  <img src="assets/screenshots/plasma-productive1.png" width="800" alt="Productive Workflow">
</p>

<p align="center">
  <img src="assets/screenshots/zed-editor1.png" width="800" alt="Zed Editor">
</p>

## Infrastructure

This configuration manages a variety of hosts:

- **roglaptop**: Primary workstation (ROG Laptop) with NVIDIA graphics and Plasma 6.
- **nixacle**: Oracle VPS for web services and server workloads.
- **diviner**: Oracle VPS for testing and secondary services.
- **vili**: Aarch64 container environment (Droidspaces).

## Key Features

### Desktop & UI
- **KDE Plasma 6**: Modern desktop environment with custom themes.
- **Niri & Material Shell**: Alternative window management experiences.
- **Fonts & Graphics**: Curated fonts and optimized NVIDIA/CUDA drivers.

### Gaming & Multimedia
- **Gaming Stack**: Steam, Heroic, PrismLauncher, MangoHUD, and GameMode.
- **Audio**: PipeWire with ALSA, PulseAudio, and JACK compatibility.

### Development & Tools
- **Languages & Frameworks**: Support for multiple environments via `devenv`.
- **VSCode**: Pre-configured with extensions and AI enhancements.
- **Virtualization**: Libvirt/QEMU, KVMFR (Looking Glass), Podman, and Distrobox.
- **Shells**: `xonsh` (primary), `zsh`, and `bash` with Starship.

### Security & Operations
- **SOPS-nix**: Secrets managed with SOPS and age.
- **Networking**: Tailscale for secure mesh networking.
- **CI/CD**: Cachix for binary caching.

## Repository Structure

```
/etc/nixos/
├── flake.nix           # Flake entry point
├── modules/
│   ├── defaults.nix    # Global default configurations
│   ├── hosts.nix       # Host definitions and metadata
│   ├── lunar/          # Feature aspects (Plasma, Gaming, Dev, etc.)
│   ├── hosts/          # Host-specific configurations
│   └── users/          # User-specific aspects
└── packages/           # Custom Nix packages
```

## Usage

Rebuild for the current host:

```bash
sudo nixos-rebuild switch --flake .#
```

Update dependencies:

```bash
nix flake update
```

## Credits

- **Dendritic Pattern**: Uses [den](https://github.com/vic/den)
