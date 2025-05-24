# LibRetro Cheats Installer for OnionOS

**LibRetro Cheats Installer** is a simple [OnionOS](https://onionui.github.io/) app that downloads and installs `.cht` cheat files from the [libretro-database](https://github.com/libretro/libretro-database) for supported emulation systems on your Miyoo Mini Plus device.

## Features

- Automatically detects enabled systems
- Downloads only relevant `.cht` files from GitHub
- Enables the "cheats" option in the RetroArch Quick menu

## Usage

1. Download the latest release
2. Extract the `LibRetroCheatsInstaller` directory to your `App` directory on your OnionOS SD card.
3. Launch the app from the Onion menu.
4. It will:
   - Detect enabled systems from the `Roms/` folder
   - Download and install matching cheat files
   - Enable the `quick_menu_show_cheats` option in RetroArch
5. At any time, press the `Menu` button to cancel and return to the main UI.

## License

This project is licensed under the terms of the  
**GNU General Public License v3.0**  
See [`LICENSE`](./LICENSE) for full details.
