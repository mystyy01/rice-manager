# rice-manager

`rice` CLI for installing/switching Hyprland rice profiles, including optional Kitty and Waybar configs.

## Install (curl | bash)

```bash
curl -fsSL https://raw.githubusercontent.com/mystyy01/rice-manager/main/install.sh | bash
```

Installer can prompt for:
- install path for `rice` binary
- rice storage root
- optional import of local `mono-glass` into your rice list

### Non-interactive install

```bash
curl -fsSL https://raw.githubusercontent.com/mystyy01/rice-manager/main/install.sh | bash -s -- --yes --bin-dir "$HOME/.local/bin" --rice-root "$HOME/.local/share/rices"
```

## Usage

```bash
rice <name>
rice switch <name>
rice install <name> <path>
rice list
rice current
rice backups
rice restore <timestamp>
rice remove <name>
```

## Rice layout

A rice can include:
- `hypr/` (or top-level hypr files with `hyprland.conf`)
- `kitty/` (optional)
- `waybar/` (optional)

When switching/restoring, `rice` can reload Hyprland and refresh Waybar/wallpaper/dock state.
