#!/bin/bash

# KOS Lite Installation Script with PC Gaming Support
# License: GPL-3.0
# Developer: Kainat Quaderee

# Display KOS Lite ASCII Art
echo "---------------------------------------------"
echo "  ██╗  ██╗  ██████╗ ███████╗     ██╗     ██╗████████╗███████╗"
echo "  ██║ ██╔╝ ██╔═══██╗██╔════╝     ██║     ██║╚══██╔══╝██╔════╝"
echo "  █████╔╝  ██║   ██║███████╗     ██║     ██║   ██║   █████╗  "
echo "  ██╔═██╗  ██║   ██║╚════██║     ██║     ██║   ██║   ██╔══╝  "
echo "  ██║  ██╗ ╚██████╔╝███████║     ███████╗██║   ██║   ███████╗"
echo "  ╚═╝  ╚═╝  ╚═════╝ ╚══════╝     ╚══════╝╚═╝   ╚═╝   ╚══════╝"
echo "---------------------------------------------"
echo

# Spinner function for background tasks
t_spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\\'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%%$temp}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Update and upgrade Termux packages
echo -e "\n\e[1;34mUpdating Termux packages...\e[0m"
pkg update -y && pkg upgrade -y & t_spinner

# Install required Termux repositories and packages, including Box64, Box86, and Wine
echo -e "\n\e[1;34mInstalling required Termux packages...\e[0m"
pkg install -y x11-repo termux-x11-nightly tur-repo pulseaudio proot-distro wget git sox virglrenderer-android mesa \
zlib box64 box86 wine wine64 wine32 & t_spinner

# Configure PulseAudio
echo -e "\n\e[1;34mConfiguring PulseAudio...\e[0m"
cat << 'EOF' >> $PREFIX/etc/pulse/default.pa
load-module module-sles-sink
load-module module-sles-source
load-module module-null-sink sink_name=virtspk sink_properties=device.description=Virtual_Speaker
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF

# Prompt for user credentials
read -p "Enter new USERNAME: " username
read -sp "Enter password: " password
echo

# Install Debian via proot-distro
echo -e "\n\e[1;34mInstalling Debian distribution...\e[0m"
proot-distro install debian & t_spinner

# Configure Debian environment
echo -e "\n\e[1;34mConfiguring Debian environment...\e[0m"
proot-distro login debian -- bash -c "

# Create user and grant sudo
useradd -m -G sudo -s /bin/bash $username
echo \"$username:$password\" | chpasswd
echo \"$username ALL=(ALL:ALL) ALL\" > /etc/sudoers.d/${username}-sudoers

# Enable i386 architecture for Wine
dpkg --add-architecture i386
apt update -y

# Update, upgrade and install desktop + gaming tools
apt upgrade -y
echo -e '\n\e[1;34mInstalling KDE desktop and core packages...\e[0m'
apt install -y plasma-desktop kde-plasma-desktop pulseaudio pulseaudio-utils pavucontrol mesa-utils nano htop easyeffects gimp

echo -e '\n\e[1;34mInstalling Wine and dependencies for PC gaming...\e[0m'
apt install -y wine64 wine32 winetricks cabextract libfaudio0 libfaudio0:i386

# Download and install Kainat OS packages
wget -O /tmp/kainat-os-sources.deb "https://downloads.sourceforge.net/projects/kainatos/files/main_arm/kainat-os-sources.deb"
dpkg -i /tmp/kainat-os-sources.deb || apt-get -f install -y
apt-get update -y
apt install -y kainat-os-core

# Cleanup
autoremove -y && apt clean

" & t_spinner

# Create launch script
echo -e "\n\e[1;34mCreating start script...\e[0m"
cat << 'EOF' > $PREFIX/bin/start-koslite
#!/bin/bash
# Start Termux X11
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :1 -ac &

# Start PulseAudio
pulseaudio --start --exit-idle-time=-1

# Start VirGL
virgl_test_server_android &

# Login to Debian and launch KDE
proot-distro login --shared-tmp --user "$username" debian -- bash -c "
    export DISPLAY=:1
    export PULSE_SERVER=127.0.0.1
    pactl load-module module-tunnel-source server=127.0.0.1
    # Launch KDE Plasma
    startplasma-x11
"
EOF
chmod +x $PREFIX/bin/start-koslite

echo "Installation complete. Run 'start-koslite' to launch your KOS Lite with PC gaming support!"
