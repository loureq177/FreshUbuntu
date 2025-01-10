# FreshUbuntu 🐧

A Bash script to set up a fresh Ubuntu 22.04 LTS environment with essential applications and configurations.

## Features ✨

- Enable firewall (UFW) 🛡️
- Update and upgrade system packages 🔄
- Remove unnecessary default applications (e.g., Firefox, Thunderbird) 🗑️
- Pin Firefox Nightly from packages.mozilla.org 🦊
- Install essential software:
  - Z-Shell with Oh-My-Zsh 💻
  - Visual Studio Code 📝
  - Development tools (Git, Docker, Node.js, Python) 🛠️
  - Flatpak ecosystem (GNOME Software Plugin, Flathub) 📦
  - Multimedia/Gaming apps (Spotify, GIMP, Steam, Heroic Launcher) 🎮
  - System utilities (GNOME Tweaks, Extension Manager, Timeshift, Stacer, htop, neofetch) ⚙️

## Usage 🛠️

1. Make the script executable:
   ```bash
   chmod +x FreshUbuntu.sh
   ```

2. Run the script:
   ```bash
   ./FreshUbuntu.sh
   ```

## Post-Installation Steps 📋

1. (Optional) Install or enable GNOME extensions:
   - Dash to Dock
   - Clipboard Indicator

2. Check or adjust Z-Shell aliases in ~/.zshrc.

3. For multi-monitor or custom refresh rates, edit:
   - ~/.config/monitors.xml

4. Fix brightness control if needed:
   - Edit /etc/default/grub with amdgpu.backlight=0

5. Reboot the system for all changes to take effect.

## Customization 🖌️

- Add/Remove Applications:
  - Modify apt commands or Flatpak installations in the script.
- Change Default Applications:
  - Adjust xdg-mime commands to suit your preferences.

## Notes 📝

- Script requires sudo privileges.
- Log file is saved as installation_log.txt.
- Some applications may need manual configuration.

Enjoy your fresh Ubuntu setup! 🎉

