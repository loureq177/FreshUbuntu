#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Error handling and logging
set -e
exec > >(tee "_installation_log.txt") 2>&1

# Function to display status messages
echo_status() {
    echo "-------------------------------------------"
    echo "$1"
    echo "-------------------------------------------"
}

# Determine real user
REAL_USER=${SUDO_USER:-$(logname || who -m | awk '{print $1}')}
REAL_USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
echo_status "Detected user: $REAL_USER with home: $REAL_USER_HOME"

# SYSTEM SETUP & UPDATES
echo_status "Setting up system..."
ufw enable || echo_status "Firewall already enabled"
apt update && apt upgrade -y
# Install essential tools
apt-get install -y dbus-x11 curl || true
add-apt-repository multiverse -y
dpkg --add-architecture i386
apt update

# CLEANUP UNWANTED APPS
echo_status "Removing unnecessary applications..."
apt remove --purge -y yelp gnome-text-editor || true
apt remove --purge -y gnome-passwordsafe || true
apt autoremove -y
apt install -y zsh
apt install -y neovim
# Add error handling for VS Code download
if ! wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb; then
    echo_status "Failed to download VS Code"
    exit 1
fi
# Check if file exists before installing
if [ -f ./vscode.deb ]; then
    apt install -y ./vscode.deb
    # Clean up the downloaded file
    rm -f ./vscode.deb
else
    echo_status "VS Code installation file not found"
    exit 1
fi
apt install -y git

apt install -y gimp
apt install -y steam
apt install -y flatpak gnome-software-plugin-flatpak
apt install -y stacer
apt install -y htop
apt install -y libreoffice

# Install Flatpak and configure Flathub repository
echo_status "Setting up Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install flatpak applications
echo_status "Installing Flatpak applications..."
su - "$REAL_USER" -c "flatpak install -y flathub com.discordapp.Discord" || echo_status "Failed to install Discord"
su - "$REAL_USER" -c "flatpak install -y flathub com.spotify.Client" || echo_status "Failed to install Spotify"
su - "$REAL_USER" -c "flatpak install -y flathub com.prusa3d.PrusaSlicer" || echo_status "Failed to install PrusaSlicer"

# SHELL SETUP
echo_status "Setting up ZSH..."
if [ ! -d "$REAL_USER_HOME/.oh-my-zsh" ]; then
    git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$REAL_USER_HOME/.oh-my-zsh"
    chown -R "$REAL_USER":"$REAL_USER" "$REAL_USER_HOME/.oh-my-zsh"
fi

# Create .zshrc
if [ -f "$REAL_USER_HOME/.zshrc" ]; then
    mv "$REAL_USER_HOME/.zshrc" "$REAL_USER_HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

cat > "$REAL_USER_HOME/.zshrc" << EOL
# Path to your oh-my-zsh installation.
export ZSH="$REAL_USER_HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source \$ZSH/oh-my-zsh.sh
export LANG=en_US.UTF-8
export EDITOR='vim'
EOL
chown "$REAL_USER":"$REAL_USER" "$REAL_USER_HOME/.zshrc"

# Set ZSH as default shell
echo_status "Setting ZSH as default shell..."
if chsh -s $(which zsh) "$REAL_USER"; then
    echo "Default shell changed to ZSH successfully"
elif usermod -s $(which zsh) "$REAL_USER"; then
    echo "Default shell changed to ZSH using usermod"
else
    echo_status "Failed to change default shell to ZSH"
fi

# Desktop settings
echo_status "Setting up desktop environment..."
# Check if running in a GNOME session
if pgrep -f "gnome-shell" > /dev/null; then
    echo "Configuring GNOME desktop settings..."
    su - "$REAL_USER" -c "gsettings set org.gnome.desktop.interface show-battery-percentage true" && \
        echo "Set battery percentage display: ON" || echo_status "Failed to set battery percentage display"
    su - "$REAL_USER" -c "gsettings set org.gnome.nautilus.desktop home-icon-visible false" && \
        echo "Set home icon visibility: OFF" || echo_status "Failed to set home icon visibility"
    su - "$REAL_USER" -c "gsettings set org.gnome.desktop.interface text-scaling-factor 1.2" && \
        echo "Set text scaling factor to 1.2" || echo_status "Failed to set text scaling factor"
else
    echo_status "GNOME Shell not detected, skipping desktop settings"
fi

# Install Extension Manager and Dash to Dock
echo_status "Installing GNOME extensions..."
apt install -y gnome-shell-extensions gnome-tweaks

# For Ubuntu 22.04+, use Extension Manager instead of chrome-gnome-shell
UBUNTU_VERSION=$(lsb_release -rs)
if [ "$(echo "$UBUNTU_VERSION >= 22.04" | bc)" -eq 1 ]; then
    echo "Installing Extension Manager for Ubuntu $UBUNTU_VERSION..."
    apt install -y gnome-shell-extension-manager || echo_status "Failed to install Extension Manager"
else
    echo "Installing chrome-gnome-shell for Ubuntu $UBUNTU_VERSION..."
    apt install -y chrome-gnome-shell || echo_status "Failed to install chrome-gnome-shell"
fi

# Install Dash to Dock
apt install -y gnome-shell-extension-dash-to-dock && \
    echo "Dash to Dock installed successfully" || \
    echo_status "Could not install Dash to Dock. May need to be installed manually."

# Enable Dash to Dock extension for the real user
if pgrep -f "gnome-shell" > /dev/null; then
    # Check which Dash to Dock extension ID is available
    if su - "$REAL_USER" -c "gnome-extensions list | grep -q 'dash-to-dock@micxgx.gmail.com'"; then
        su - "$REAL_USER" -c "gnome-extensions enable dash-to-dock@micxgx.gmail.com" && \
            echo "Dash to Dock extension enabled" || \
            echo_status "Could not enable Dash to Dock automatically. Please enable it manually."
    elif su - "$REAL_USER" -c "gnome-extensions list | grep -q 'ubuntu-dock@ubuntu.com'"; then
        su - "$REAL_USER" -c "gnome-extensions enable ubuntu-dock@ubuntu.com" && \
            echo "Ubuntu Dock extension enabled" || \
            echo_status "Could not enable Ubuntu Dock automatically. Please enable it manually."
    else
        echo_status "No compatible dock extension found. Please install and enable manually."
    fi
else
    echo_status "GNOME Shell not running, skipping extension enabling"
fi

# Final cleanup
echo_status "Performing final cleanup..."
echo "Updating packages..."
apt update && apt upgrade -y
echo "Removing unnecessary packages..."
apt autoremove -y && apt autoclean -y && apt clean -y
echo "Cleaning temporary files..."
rm -rf /tmp/*

echo_status "Installation completed! Please log out and log back in for all changes to take effect."
echo "You may need to restart your computer for all changes to take effect."