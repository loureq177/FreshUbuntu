#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (with sudo)"
    exit 1
fi

# Error handling
set -e
trap 'echo "An error occurred. Exiting..."; exit 1' ERR

# Check internet connection
if ! ping -c 1 google.com &> /dev/null; then
    echo "No internet connection. Please connect and try again."
    exit 1
fi

# Create a log file
exec 1> >(tee "installation_log.txt") 2>&1

# Function to print status messages
print_status() {
    echo "-------------------------------------------"
    echo "$1..."
    echo "-------------------------------------------"
}

# Enable Firewall
print_status "Enabling Firewall"
sudo ufw enable

# Update package list and upgrade all apps/drivers
print_status "Updating package list and upgrading all apps/drivers"
sudo apt update && sudo apt upgrade -y

# Uninstall unnecessary apps
print_status "Uninstalling unnecessary apps"
sudo apt remove --purge firefox && sudo apt autoremove -y
sudo apt remove --purge gnome-power-manager && sudo apt autoremove -y
sudo apt remove --purge yelp && sudo apt autoremove -y
sudo apt remove --purge gnome-system-monitor && sudo apt autoremove -y

# Install necessary apps
print_status "Installing necessary apps"
sudo install -d -m 0755 /etc/apt/keyrings -y
# Z-Shell
sudo apt install zsh -y
# Oh-My-Zsh
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
# Firefox Nightly
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla 
sudo apt update && sudo apt install firefox -y
# Flatpak
sudo apt install flatpak -y
sudo apt install gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Visual Studio Code
wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb
sudo apt install ./vscode.deb -y
# Git
sudo apt install git -y
# venv
sudo apt install python3-venv -y
# pip
sudo apt install python3-pip -y
# Gnome Tweaks
sudo apt install gnome-tweaks -y
# Spotify
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt update && sudo apt install spotify-client -y
# Steam
sudo apt install steam -y
# PrusaSlicer
flatpak install flathub com.prusa3d.PrusaSlicer -y
# Extension Manager
flatpak run com.mattjakeman.ExtensionManager -y
# net-tools (for ifconfig)
sudo apt install net-tools -y
# A better system monitor
flatpak install flathub io.missioncenter.MissionCenter -y
# Heroic Games Launcher
flatpak install flathub com.heroicgameslauncher.hgl -y
# GIMP
flatpak install flathub org.gimp.GIMP -y
# Alpaca
flatpak install flathub com.jeffser.Alpaca -y

# Add useful development tools
print_status "Installing additional development tools"
# Docker
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
# Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install nodejs -y
# Build essentials
sudo apt install build-essential -y

# Add some useful system utilities
print_status "Installing system utilities"
# Timeshift for system backup
sudo apt install timeshift -y
# Stacer for system optimization
sudo apt install stacer -y
# htop for better process monitoring
sudo apt install htop -y
# neofetch for system info
sudo apt install neofetch -y

# Set Z-Shell as the default terminal
print_status "Setting Z-Shell as the default terminal"
chsh -s $(which zsh)

# Set Firefox Nightly as the default PDF app
print_status "Setting Firefox Nightly as the default PDF app"
xdg-mime default firefox-trunk.desktop application/pdf

# Clean tmp files
print_status "Cleaning tmp files"
sudo rm -rf /tmp/*

# Clean apt cache
print_status "Cleaning apt cache"
sudo apt autoremove -y
sudo apt autoclean -y
sudo apt clean -y

# Add to .zshrc
echo '
# Custom aliases
alias update="sudo apt update && sudo apt upgrade -y"
alias clean="sudo apt autoremove -y && sudo apt autoclean -y"
alias ls="ls -1 --color=auto"
alias ll="ls -lah"
alias neofetch="neofetch --ascii_distro ubuntu"
' >> ~/.zshrc

print_status "Installation completed successfully!"
echo "Log file has been saved as installation_log.txt"

echo "Remember to:

1. # If plugged-in, update monitor refresh rate to 74 Hz
    nano ~/.config/monitors.xml

2. If brightness control does not work, try the following:
    sudo nano /etc/default/grub
    Insert the above parameter in GRUB_CMDLINE_LINUX_DEFAULT like this:
    GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash amdgpu.backlight=0\"
    then run:
    sudo update-grub

3. Reboot system"
