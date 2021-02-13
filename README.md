# media-launcher

Track and launch media.

### Installation

1. Install rofi.
2. Install dependencies for `main.py`, in this case only [natsort](https://github.com/SethMMorton/natsort)
3. Place the helper script `update_ep.lua` into the scripts directory of mpv (i.e `~/.config/mpv/scripts`)
4. Link the `media_launcher` bash script to a folder in PATH. Alternatively, copy both `media_launcher` and `main.py` into a folder in PATH.
5. Edit `mediaDir` to point to media directory.

### Usage

1. Bind a key in window manager of choice to execute `media_launcher`.
2. Use the keybind to open the launcher.

### Configuration

This script expects a standard layout for media: The folder contains the title with media files contained directly in them. It is able to handle subdirectories.

### Demo

See a video demo [here](https://streamable.com/s5n9hl)

### Todo

- Easily handle configuration (currently multiple instances of `mediaDir`; hard to change)
