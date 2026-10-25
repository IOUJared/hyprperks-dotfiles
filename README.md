## hyprperks-dotfiles

Fork of [hyprwm/hyprperks-dotfiles](https://github.com/hyprwm/hyprperks-dotfiles),
based on the `v0.56.0` snapshot, carrying my personal changes.

### Changes in this fork

All changes live under `v0.56.0/dotfiles/` so they stay diffable against upstream.

- Fixed Rosé Pine palette instead of wallpaper-derived colors: `scripts/apply-rose-pine`
  runs matugen against `matugen/rose-pine.json`, and `scripts/wallpaper.sh` only sets
  the wallpaper.
- UWSM-managed apps (`alacritty`, `zen-browser`, `thunar`), `hyprlauncher` instead of
  walker, and ordered session shutdown with `uwsm stop`.
- Custom `hyprlock`/`hypridle` configs, monitor layout, workspace/bind set, and
  per-game window rules and autostart hooks under `hyprland/custom.d/`.
- Quickshell, kitty, GTK, Qt and Kvantum updates for the Rosé Pine theme.

### Installing

```sh
cd v0.56.0/dotfiles
./setup.sh
```

`setup.sh` installs the file set of this fork: Hyprland (including `custom.d/`,
`scheme/`, `script/`, `sounds/`), quickshell, matugen, kitty, GTK, Qt/Kvantum and the
`hyprland-de` scripts, and points the gsettings themes at Bibata/Rosé Pine. It
overwrites the files it manages, including `kitty.conf` and the GTK configs, and it no
longer installs walker or wallust.

### Local prerequisites

Paths are intentionally absolute for my machine. The setup also expects these
external pieces, which are not stored in this repo:

- the `RosePine-Custom` GTK theme under `~/.local/share/themes/`, whose
  `gtk-3.0/assets` symlink targets `/usr/share/themes/rose-pine-gtk/assets`
- `Bibata-Modern-Classic` cursors and `rose-pine-icons`
- the `Lato` font
- a wallpaper at `~/Pictures/Wallpapers/mountain.png`
- `~/avatar.jpg` for the lock screen

The `third-party/` tree is kept from upstream for reference only; this setup uses the
icon, cursor and GTK themes installed by the packages above.

### Tests

```sh
cd v0.56.0/dotfiles
./tests/setup_test.sh
```

The test runs `setup.sh` against a throwaway `HOME` with stubbed `gsettings`,
`systemctl`, `hyprctl` and `matugen`, then checks the installed file set, that
`wallpaper.sh` finds its sibling `apply-rose-pine`, the gsettings values, and that a
second run is safe.

### Updating from upstream

```sh
git fetch upstream
git merge upstream/main
```

## Usage

These dotfiles can mostly be used as-is. Some scripts might expect a HLDE structure for the locations of files.

It is generally not recommended to try to recreate the structure of HLDE itself, as I'd invite you to pick parts and integrate them
into your setup manually. This way you're gaining valuable experience in maintaining your own desktop :)

## Special thanks

Thank you to End-4 and Outfoxxed for helping with initial work on these dotfiles, and the community patches submitted on the Hyprland Forum.

## Licensing

All dotfiles are released under MIT. Themes included under `third-party/` are copies from their original sources, and may be licensed under different
conditions.


