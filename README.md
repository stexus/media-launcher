# media-launcher

Track and launch media.

### Features

Locally tracks episode completion and automatic Anilist updating. Rofi launcher shows shows in most recently played order.

### Installation

1. Install rofi.
2. `git clone` this repository and install dependencies ([natsort](https://github.com/SethMMorton/natsort) and [rofi-blocks](https://github.com/OmarCastro/rofi-blocks))
3. Open `install.sh` and review the `path` and `mpv` variables -- they should correspond to their respective areas in your machine.
4. Run `install.sh` (`./install.sh`)
5. Edit `media_dir` in `media_launcher` to point to the master media directory. Edit `mediadir_name` in `mpv/update_ep.lua` to be the name of the folder containing media (i.e `Anime`; make sure directory names are same between master directory and other directories). This supports symlinking across drives.\*
6. In `helpers/secrets.py`, fill in your token. Obtain a token [here](https://anilist-token.glitch.me/) (courtesy of MrScopes/anilist.js)

\*make this process more user friendly

### Usage

1. Bind a key in window manager of choice to execute `media_launcher`.
2. Use the keybind to open the launcher.
3. In mpv, `ctrl+w` manually completes the current episode (next episode plays on start). `ctrl+shift+w` completes the previous episode (current episode plays on start).
4. `Alt+a` to find and select the anilist show at the beginning of a new series.

Example

- Attack on Titan/S1
- Attack on Titan/S2
- Attack on Titan/S3

In the first episode of S1, press `Alt+a` to select the first season using the provided anilist searcher via rofi. Proceed accordingly with S2 and S3. This sets an appropriate offset between the local episode number and anilist.

### Configuration

This script expects a standard layout for media: The folder contains the title with media files contained directly in them. It is able to handle subdirectories. (i.e S1 and S2 subdirectories)

### Demo

See a video demo [here](https://streamable.com/s5n9hl)

### Todo

- Easily handle configuration (currently multiple instances of `media_dir`; hard to change)
