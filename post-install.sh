# Post-install
# Setup yay
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

# Install hyprland and essential packages
yay -S --needed --noconfirm \
  hyprland greetd greetd-tuigreet uwsm \
  hyprpaper waybar wofi mako wlogout hyprlock hypridle \
  thunar file-roller \
  ghostty \
  starship fish \
  blueman bluez bluez-utils \
  wl-clipboard \
  firefox \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk egl-wayland \
  pavucontrol wireplumber pipewire-pulse \
  network-manager-applet \
  neovim fzf btop \
  swww \
  plymouth

# Setup Hyprland for Nvidia
yay -S --needed --noconfirm \
  qt6-wayland qt5-wayland qt6ct qt5ct libva libva-nvidia-driver-git
# Add: options nvidia_drm modeset=1
sudo nvim /etc/modprobe.d/nvidia.conf

# Fix sound
sudo pacman -S sof-firmware alsa-ucm-conf alsa-utils wireplumber pipewire pipewire-alsa pipewire-pulse pipewire-jack

# Install lazyvim

# Install all conf files from dotfiles repo: hyprland, tuigreet, lazyvim
# rice tuigreet
# wofi
# waybar
# wallpaper
# theme gtk etc
# Install
# SSH KEYS FOR GITHUB AND AUTO IN FISH SHELL
# Services
loginctl enable-linger sb74
systemctl --user enable \
  xdg-desktop-portal.service \
  xdg-desktop-portal-hyprland.service \
  pipewire.service \
  wireplumber.service \
  hypridle.service \
  hyprland-session.target
systemctl --user enable \
  mako.service \
  wlsunset.service # if you want screen warmth (f.lux/redshift)
systemctl enable NetworkManager
systemctl enable bluetooth      # if needed
systemctl enable greetd         # if using tuigreet
systemctl enable zram-generator # if using zram
# change how fn behaves
# fix keyboard
# console font nerdfonts etc
# Set up plymouth
# Set up zram
# final checks on nvidia hyprland envs
# Snapper install and configuration
pacman -S snapper btrfs-assistant
snapper -c root create-config /
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
usermod -aG snapper sb74
# Set up chezmoi
# Secure SSH
# Final code to test stuff
