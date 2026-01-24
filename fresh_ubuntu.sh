#! /usr/bin/env bash
set -euo pipefail

# =====================[ USER CHECK ]===================== #
if [ "$EUID" -eq 0 ]; then
  echo -e "\033[0;31m[ERROR] Please run as normal user (DO NOT USE SUDO to start script)"
  exit 1
fi

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# =====================[ COLORS & LOGGING ]===================== #
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_FILE="/tmp/ubuntu-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; sleep 2; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; sleep 2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; sleep 2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; sleep 2; }

log_info "Running setup for user: $USER"
log_info "Home directory: $HOME"

# =====================[ GIT SETUP ]=================== #
log_info "Setting up git..."
git config --global init.defaultBranch main
CURRENT_NAME=$(git config --global --get user.name || true)
CURRENT_EMAIL=$(git config --global --get user.email || true)
if [[ -n "$CURRENT_NAME" ]] && [[ -n "$CURRENT_EMAIL" ]]; then
  log_info "Git is already configured as: $CURRENT_NAME <$CURRENT_EMAIL> — skipping setup."
else
  if [[ -z "$CURRENT_NAME" ]]; then
    read -p "Enter your nick for git config --global user.name: " username
    git config --global user.name "$username"
  fi

  if [[ -z "$CURRENT_EMAIL" ]]; then
    read -p "Enter your email for git config --global user.email: " email
    git config --global user.email "$email"
  fi

  log_ok "Git has been correctly set up."
fi
 
# =========================[ DRIVER UPDATE ]========================= #
log_info "Updating drivers..."
sudo fwupdmgr refresh --force || true
sudo fwupdmgr get-updates || true
sudo fwupdmgr update --assume-yes || true
log_ok "Drivers updated check complete!"

# =====================[ JETBRAINS MONO NERD FONT ]===================== #
log_info "Installing JetBrains Mono Nerd Font..."

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
FONT_DIR="/usr/share/fonts/JetBrainsMonoNerd"

if [ ! -d "$FONT_DIR" ]; then
  sudo mkdir -p "$FONT_DIR"
  curl -fLo /tmp/JetBrainsMono.zip "$FONT_URL" \
    && sudo unzip -qo /tmp/JetBrainsMono.zip -d "$FONT_DIR" \
    && sudo fc-cache -f -v \
    && log_ok "JetBrains Mono Nerd Font installed." \
    || log_warn "Failed to install JetBrains Mono Nerd Font."
else
  log_info "JetBrains Mono Nerd Font already installed — skipping."
fi

# =====================[ GNOME CONFIGURATION ]===================== #
log_info "Configuring GNOME environment..."
log_info "Applying GNOME preferences..."
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' || log_warn "GTK theme failed"
gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || log_warn "Color scheme failed"
gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 12'
gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 12'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font Mono 14' \
  && log_ok "Default monospace font set to JetBrainsMono Nerd Font Mono." \
  || log_warn "Failed to set JetBrains Mono Nerd Font as default."
gsettings set org.gnome.desktop.interface text-scaling-factor 1.10
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.wm.preferences auto-raise true
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.peripherals.keyboard delay 200
log_ok "GNOME settings applied."
 
# =====================[ GNOME EXTENSIONS ]===================== #
gnome-extensions disable ubuntu-dock@ubuntu.com
gnome-extensions disable ding@rastersoft.com

# =====================[ AUDIO ]===================== #
log_info "Setting microphone volume..."
wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.3 && log_ok "Microphone set to 30%" || log_warn "Could not set volume"

# =====================[ ADD REPOSITORIES ]===================== #
sudo add-apt-repository -y multiverse
sudo add-apt-repository -y universe

# =====================[ DOCKER ]===================== #
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# =====================[ EZA ]===================== #
log_info "Configuring Eza repository..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

# =====================[ GO ]===================== #
sudo add-apt-repository -y ppa:longsleep/golang-backports

# =====================[ VS CODE ]===================== #
log_info "Configuring Visual Studio Code repository..."
sudo rm -f /etc/apt/sources.list.d/vscode.list /etc/apt/keyrings/vscode.gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/vscode.gpg > /dev/null
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

# =====================[ UPDATE ]===================== #
sudo apt update -y

# =====================[ REMOVE APT PACKAGES ]===================== #
log_info "Removing unnecessary applications..."
sudo apt remove -y \
firefox \
orca \
yelp
log_ok "Unnecessary applications removed."

# =====================[ UPDATE APT PACKAGES ]===================== #
log_info "Updating system..."
sudo apt update && sudo apt upgrade -y
log_ok "System up to date."

# =====================[ INSTALL APT PACKAGES ]===================== #
sudo apt install -y \
  bat \
  btop \
  ca-certificates \
  cargo \
  cbonsai \
  cmatrix \
  code \
  containerd.io \
  curl \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  eza \
  fastfetch \
  flatpak \
  fzf \
  gcc \
  gnome-software-plugin-flatpak \
  gnome-shell-extensions \
  gnome-tweaks \
  gh \
  git \
  git-lfs \
  neovim \
  python3-pip \
  python3-virtualenv \
  rclone \
  rclone-browser \
  sox \
  stacer \
  stow \
  tealdeer \
  tmux \
  traceroute \
  wl-clipboard \
  zoxide \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting
log_ok "Essential applications installed."

# =====================[ BAT FIX ]===================== #
ln -sf /usr/bin/batcat ~/.local/bin/batcat

# =====================[ BROWSER & SHELL SETUP ]===================== #
log_info "Setting Zen Browser as default..."
xdg-settings set default-web-browser app.zen_browser.zen.desktop
log_ok "Zen Browser set as default."

# =====================[ INSTALL OLLAMA ]===================== #
log_info "Checking for Ollama..."
if command -v ollama &> /dev/null; then
    log_info "Ollama is already installed — skipping."
else
    log_info "Ollama not found. Starting installation..."
    curl -fsSL https://ollama.com/install.sh | sh
    log_ok "Ollama installed successfully."
fi

# =====================[ FLATPAK SETUP ]===================== #
log_info "Setting up Flatpak repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
log_ok "Flathub repository ready."
flatpak_apps=(
  app.zen_browser.zen \
  com.discordapp.Discord/x86_64/stable \
  com.github.PintaProject.Pinta \
  com.mattjakeman.ExtensionManager \
  com.prusa3d.PrusaSlicer \
  com.spotify.Client \
  com.valvesoftware.Steam \
  io.dbeaver.DBeaverCommunity \
  md.obsidian.Obsidian \
  org.gnome.Snapshot \
  org.gnome.Boxes
)
log_info "Installing Flatpak applications (batch mode)..."
flatpak install \
	-y \
	--system \
	flathub "${flatpak_apps[@]}" \
  && log_ok "All Flatpak applications installed successfully." \
  || log_warn "There were issues installing some Flatpak applications."


# =====================[ ENABLE FIREWALL ]===================== #
sudo ufw --force enable

# =====================[ FIX LOFREE KEYBOARD ]===================== #
log_info "Fixing Lofree keyboard (Function keys)..."
sudo modprobe hid_apple
if [ -d "/sys/module/hid_apple/parameters" ]; then
    echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode > /dev/null
    log_ok "hid_apple module configured."
else
    log_warn "hid_apple module not found. Is the keyboard connected?"
fi
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="hid_apple.fnmode=2 /' /etc/default/grub
sudo update-grub

# =====================[ UV INSTALLER ]===================== #
log_info "Installing uv for Python..."
if command -v uv &> /dev/null; then
    log_info "uv already installed — skipping."
else
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# =====================[ STARSHIP PROMPT ]===================== #
log_info "Installing Starship Prompt..."

if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  log_ok "Starship binary installed."
else
  log_info "Starship already installed — skipping binary download."
fi
STARSHIP_INIT='eval "$(starship init zsh)"'
if ! grep -qF "$STARSHIP_INIT" "$HOME/.zshrc"; then
  echo "" >> "$HOME/.zshrc"
  echo "$STARSHIP_INIT" >> "$HOME/.zshrc"
  log_ok "Added Starship init to .zshrc"
else
  log_info "Starship already configured in .zshrc — skipping."
fi

# =====================[ SET ZSH AS DEFAULT ]===================== #
log_info "Setting ZSH as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER"
    log_ok "Shell changed to ZSH. It will take effect after logout/login."
else
    log_info "ZSH is already your default shell."
fi

# =====================[ MOUNTING EXTERNAL HOME ]===================== #
log_info "Configuring 512 GB drive..."
UUID="688f55cd-90c1-4766-b4f9-5e1a812fe16a"
if ! grep -q "$UUID" /etc/fstab; then
    sudo sed -i '/[[:space:]]\/home[[:space:]]/d' /etc/fstab
    echo "UUID=$UUID /home ext4 defaults 0 2" | sudo tee -a /etc/fstab > /dev/null
fi
sudo mount -a
if [ "$(stat -c '%U' /home/$USER 2>/dev/null)" != "$USER" ]; then
    sudo chown -R $USER:$USER /home/$USER
    sudo chmod 700 /home/$USER
fi
log_ok "Home drive ready."

# =====================[ CLEANUP ]===================== #
log_info "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean -y
sudo apt clean -y
log_ok "System cleanup complete."

# =====================[ FINISH ]===================== #
echo ""
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} INSTALLATION COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Logs saved to: $LOG_FILE"
echo ""

# todo
# extensions
# brew
# brew apps
# group install
