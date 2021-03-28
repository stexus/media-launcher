# media-launcher

Track and launch media.

### Features

Locally tracks episode completion and automatic Anilist updating. Rofi launcher shows shows in most recently played order.

### Installation

1. Install rofi.
2. Install dependencies ([natsort](https://github.com/SethMMorton/natsort) and [rofi-blocks](https://github.com/OmarCastro/rofi-blocks))
3. Open `install.sh` and review the `path` and `mpv` variables -- they should correspond to their respective areas in your machine.
4. Run `install.sh` (`./install.sh`)
5. Edit `mediaDir` to point to media directory.

### Usage

1. Bind a key in window manager of choice to execute `media_launcher`.
2. Use the keybind to open the launcher.

### Configuration

This script expects a standard layout for media: The folder contains the title with media files contained directly in them. It is able to handle subdirectories. (i.e S1 and S2 subdirectories)

### Demo

See a video demo [here](https://streamable.com/s5n9hl)

### Todo

- Easily handle configuration (currently multiple instances of `mediaDir`; hard to change)
