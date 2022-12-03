#!/bin/bash

echo 'My configuration'
export EDITOR='nvim'

# Initial config
usage() { echo "Usage: $0 [-d <desktop>] " 1>&2; exit 1; }

while getopts ":d:" o; do
  case "${o}" in
    d)
      if [[ ${OPTARG} == 'dwm' || ${OPTARG} == 'sway' || ${OPTARG} == 'bruce' || ${OPTARG} == 'skip' ]]; then
        d=${OPTARG}
      fi
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${d}" ]; then
    usage
fi

function rice() {
  echo 'Create symlinks'
  symlinks

  echo 'unjewgled-chromium repos'
  unjewgle

  echo 'ChaoticAUR repos'
  chaotic

  echo 'Install packages'
  install_packages
  
  if [ $d == 'bruce' ]; then
  	echo 'Setup gnome'
  	gnome_setup
  fi
}

function unjewgle() {
  read -p 'Unjewgled repos? [y/N]: ' unjewgle
  if [[ $unjewgle == 'y' || $unjewgle == 'Y' ]]; then
    curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | sudo pacman-key -a -
echo '
[home_ungoogled_chromium_Arch]
SigLevel = Required TrustAll
Server = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/$arch' | sudo tee --append /etc/pacman.conf
  fi
}

function chaotic() {
  read -p 'Enable ChaoticAUR repo? [y/N]: ' chaos
  if [[ $chaos == 'y' || $chaos == 'Y' ]]; then
    sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key FBA220DFC880C036
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    sudo sh -c 'cat >> /etc/pacman.conf' <<EOF
  
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

  fi
}

function symlinks() {
  
  # Create symlinks (will overwrite old dotfiles)
  read -p 'Symlink dotfiles? [y/N]: ' dots
  if [[ $dots == 'y' || $dots == 'Y' ]]; then
    mkdir $HOME/.config
    ln -sfn $HOME/dotfiles/.config/* $HOME/.config
  
    files="vimrc rtorrent.rc bashrc tmux.conf xinitrc inputrc"
    for file in ${files}; do
        echo "Creating symlink to $file in home directory."
        ln -sfn $HOME/dotfiles/.${file} $HOME/.${file}
    done
    sudo chmod -R +x $HOME/dotfiles/bin
    sudo ln -sfn $HOME/dotfiles/bin/* /usr/bin/
  fi

}

function install_packages() {
    local packages=''

    read -p 'Install packages? [y/N]: ' pack
    if [[ $pack == 'y' || $pack == 'Y' ]]; then
        if [ $d == 'skip' ]; then
          echo 'No desktop'
        elif [ $d == 'dwm' ]; then
          packages+=' xorg-server xorg-xinit
          xorg-xsetroot xorg-xbacklight xorg-xrandr xclip xsel dmenu clipmenu
          slock' 
        elif [ $d == 'sway' ]; then
          packages+=' sway swaylock swaybg foot
          wl-clipboard clipman xorg-server-xwayland wofi slurp grim
          xdg-desktop-portal xdg-desktop-portal-wlr'
        fi 

    # misc
    packages+=' paru man-db alsa-utils net-tools pkgfile xclip dosfstools
    dmidecode unrar unzip zip p7zip acpi bash-completion htop openssh sshfs
    rsync lm_sensors fzf tmux aria2 wget nnn ttf-hack ttf-sazanami ttf-dejavu
    ttf-inconsolata tamsyn-font'

    sudo pacman -Sy --noconfirm $packages
  fi
}

function gnome_setup() {
  local packages=''
  local extend=''

  # core
  packages+=' gnome-shell gnome-control-center gnome-console
  gnome-tweaks gnome-system-monitor wl-clipboard xdg-desktop-portal
  xdg-desktop-portal-gnome xdg-user-dirs-gtk'
  # audio
  packages+=' pipewire pipewire-alsa pipewire-pulse wireplumber gst-plugin-gtk
  gst-libav gst-plugin-pipewire gst-plugins-good'
  # network
  packages+=' networkmanager-iwd'
  # optional
  packages+=' gdm gnome-keyring seahorse alacarte power-profiles-daemon
  gvfs-google gnome-remote-desktop gnome-user-share rygel file-roller baobab
  gnome-boxes gnome-connections gnome-clocks gnome-weather gnome-calculator
  gnome-characters gnome-color-manager gnome-font-viewer gnome-logs gnome-text-editor'
  # misc
  packages+=' ungoogled-chromium epiphany thunderbird nautilus eog evince warp
  celluloid amberol deluge-gtk dino python-setuptools ffmpegthumbnailer yt-dlp'
  # extensions
  extend+=' gnome-shell-extension-appindicator
  gnome-shell-extension-dash-to-dock
  gnome-shell-pomodoro
  gnome-shell-extension-unite-git
  gnome-shell-extension-blur-my-shell-git
  gnome-shell-extension-runcat-git
  gnome-shell-extension-quick-settings-tweaks-git'
  # ubuntu tweaks
  packages+=' yaru-gnome-shell-theme yaru-sound-theme yaru-gtksourceview-theme
  yaru-icon-theme yaru-gtk-theme ttf-ubuntu-font-family'
    
  paru -Sy --noconfirm $packages $extend

  gsettings set org.gnome.TextEditor keybindings vim # or 'default'
  gsettings set org.gnome.desktop.background picture-uri none
  gsettings set org.gnome.desktop.background primary-color 151515
#  gsettings set org.gnome.shell disable-extension-version-validation "true"

  mkdir -p /usr/share/gnome-shell/modes
  sudo sh -c 'cat >> /usr/share/gnome-shell/modes/rice.json' <<EOF 
{
    "parentMode": "user",
    "stylesheetName": "Yaru-blue-dark/gnome-shell.css",
    "themeResourceName": "gnome-shell-theme.gresource",
    "iconsResourceName": "gnome-shell-icons.gresource",
    "enabledExtensions": [
        "appindicatorsupport@rgcjonas.gmail.com",
        "dash-to-dock@micxgx.gmail.com",
        "unite@hardpixel.eu",
        "quick-settings-tweaks@qwreey"
    ]
}
EOF

  sudo sh -c 'cat >> /usr/share/wayland-sessions/Rice.desktop' <<EOF
[Desktop Entry]
Name=Rice
Comment=Riced session on gayland
Exec=env GNOME_SHELL_SESSION_MODE=rice gnome-session
TryExec=gnome-session
Type=Application
DesktopNames=Palace
X-GDM-SessionRegisters=true
EOF
  
  sudo cp /usr/share/wayland-sessions/Rice.desktop /usr/share/xsessions/Rice-xorg.desktop
  sudo sed -i 's/^Name=.*$/Name=Rice on X/g' /usr/share/xsessions/Rice-xorg.desktop
  sudo sed -i 's/^Comment=.*$/Comment=Riced session on X/g' /usr/share/xsessions/Rice-xorg.desktop

  sudo systemctl enable gdm
}

rice

echo '------'
echo 'Done'
