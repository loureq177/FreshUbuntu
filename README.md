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

Make the script executable and run the script:
   ```bash
   chmod +x fresh_ubuntu.sh
   sudo ./fresh_ubuntu.sh
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
   chmod +x fresh_ubuntu.sh
   ./fresh_ubuntu.sh
   
    
## To Do
- fix_battery_health_wayland()
- fprintd enroll
- pam-auth-update
- usuwać z paska zadań libre office writer, app center i help
- ustawiać JetBrains Mono jako domyślna w Monospace Text
- odświeżanie na 74Hz
- mikrofon na 40% volume
- fn keys w lofree
- ustawiać automatycznie ikonkę na jakąś wybraną (będzie w katalogu skryptu)
- przepisać to zgodnie z design patterns
- preferences w terminalu
    - transparency: true (40%)
    - show scrollbar: false
    - use colors from system theme: false
    - built-in schemes: green on black
    - initial terminal size: 130 x 30
- złączyć ten fragment:
#!/bin/bash

set -e

# Ścieżka instalacji czcionek lokalnie
FONT_DIR="$HOME/.local/share/fonts"

# Tymczasowy katalog
TMP_DIR=$(mktemp -d)

echo "📥 Pobieranie JetBrains Mono..."
wget -qO "$TMP_DIR/jetbrains-mono.zip" https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip

echo "📦 Wypakowywanie..."
unzip -q "$TMP_DIR/jetbrains-mono.zip" -d "$TMP_DIR"

echo "📁 Instalacja czcionek do $FONT_DIR"
mkdir -p "$FONT_DIR"
cp "$TMP_DIR/fonts/ttf/"*.ttf "$FONT_DIR"

echo "🔄 Odświeżanie cache czcionek..."
fc-cache -f "$FONT_DIR"

echo "✅ JetBrains Mono zainstalowana!"
echo "⚙️ Ustaw ją ręcznie jako czcionkę w swoim emulatorze terminala."

# Sprzątanie
rm -rf "$TMP_DIR"

