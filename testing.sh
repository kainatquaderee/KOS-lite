#!/bin/bash

# KOS Lite Installation Script (Debian-based, unbranded, now with gaming support)
# License: GPL-3.0
# Developer: Kainat Quaderee

# Display KOS Lite ASCII Logo
echo "---------------------------------------------"
echo "  ██╗  ██╗  ██████╗ ███████╗     ██╗     ██╗████████╗███████╗"
echo "  ██║ ██╔╝ ██╔═══██╗██╔════╝     ██║     ██║╚══██╔══╝██╔════╝"
echo "  █████╔╝  ██║   ██║███████╗     ██║     ██║   ██║   █████╗  "
echo "  ██╔═██╗  ██║   ██║╚════██║     ██║     ██║   ██║   ██╔══╝  "
echo "  ██║  ██╗ ╚██████╔╝███████║     ███████╗██║   ██║   ███████╗"
echo "  ╚═╝  ╚═╝  ╚═════╝ ╚══════╝     ╚══════╝╚═╝   ╚═╝   ╚══════╝"
echo "---------------------------------------------"
echo "KOS Lite (Debian) - Lightweight Desktop for Termux"
echo ""

# Spinning loader animation
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Update and upgrade Termux packages
echo -e "\n\e[1;34mUpdating and upgrading Termux packages...\e[0m"
pkg update -y && pkg upgrade -y & spinner

# Install necessary repos & packages
echo -e "\n\e[1;34mInstalling required repositories and packages...\e[0m"
pkg install -y x11-repo termux-x11-nightly tur-repo pulseaudio proot-distro wget git sox virglrenderer-android mesa zlib & spinner

# Configure PulseAudio in Termux
echo -e "\n\e[1;34mConfiguring PulseAudio settings...\e[0m"
cat << 'EOF' >> $PREFIX/etc/pulse/default.pa
load-module module-sles-sink
load-module module-sles-source
load-module module-null-sink sink_name=virtspk sink_properties=device.description=Virtual_Speaker
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF

# Prompt for new user credentials
read -p "Enter your new USERNAME: " username
read -sp "Enter password for new user: " password
echo ""

# Install Debian via proot-distro
echo -e "\n\e[1;34mInstalling Debian distribution...\e[0m"
proot-distro install debian & spinner

# Configure inside Debian
echo -e "\n\e[1;34mEntering Debian to configure system...\e[0m"
proot-distro login debian -- bash -c "

# Create a new user with sudo privileges
useradd -m -G sudo -s /bin/bash $username
echo \"$username:$password\" | chpasswd
mkdir -p /etc/sudoers.d
echo \"$username ALL=(ALL:ALL) ALL\" > /etc/sudoers.d/${username}-sudoers

# Update & upgrade inside Debian
apt update -y && apt upgrade -y

# Download and install KainatOS core packages
echo -e '\n\e[1;34mDownloading kainat-os-sources.deb...\e[0m'
wget -O /home/$username/kainat-os-sources.deb https://download.sourceforge.net/kainatos/main_arm/kainat-os-sources.deb
echo -e '\n\e[1;34mInstalling kainat-os-sources.deb...\e[0m'
dpkg -i /home/$username/kainat-os-sources.deb || apt -f install -y
rm /home/$username/kainat-os-sources.deb
echo -e '\n\e[1;34mInstalling kainat-os-core...\e[0m'
apt update -y
apt install -y kainat-os-core
#cp the /etc/skel to home
cp -r /etc/skel/. /home/$username/
# Install KDE Plasma DE
apt install -y plasma-desktop kde-plasma-desktop

# Install audio, GPU, and utilities
apt install -y pulseaudio pulseaudio-utils pavucontrol mesa-utils nano htop easyeffects gimp

# — New Gaming Support Section —
echo -e '\n\e[1;34mSetting up gaming support (Box64, Box86, Wine, Lutris)...\e[0m'

# Enable 32‑bit support
dpkg --add-architecture i386
apt update -y

# Install Box64 (x86_64 emulator) & Box86 (x86 emulator)
apt install -y box64 box86

# Install Wine for running Windows games
apt install -y wine wine32 wine64

# Install Lutris game manager
apt install -y lutris

# If you need Proton support under Wine, you can configure it later via Winetricks.

# Clean up
apt autoremove -y && apt clean

" & spinner

# Create Termux start script
echo -e "\n\e[1;34mCreating start script for KOS Lite...\e[0m"
cat << 'EOF' > $PREFIX/bin/start-koslite
#!/bin/bash
source $PREFIX/etc/xuname

# Launch X11, PulseAudio & VirGL
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
XDG_RUNTIME_DIR=\${TMPDIR}
termux-x11 :1 -ac &
pulseaudio --start --exit-idle-time=-1
virgl_test_server_android &

# Login to Debian and start KDE
proot-distro login debian --user $username --shared-tmp -- bash -c "
    export DISPLAY=:1
    export PULSE_SERVER=127.0.0.1
    pactl load-module module-tunnel-source server=127.0.0.1
    startplasma-x11
"
EOF
chmod +x $PREFIX/bin/start-koslite

# Save username
echo "username=$username" > $PREFIX/etc/xuname

echo -e "\nInstallation complete! Run 'start-koslite' to launch your Debian‑based desktop with gaming support."
