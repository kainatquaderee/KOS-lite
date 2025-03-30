#!/bin/bash

# KOS Lite Installation Script
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
echo "KOS Lite (Kainat OS Lite) - Lightweight Desktop for Termux"
echo ""

# Animation: Spinning loader
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Update and upgrade Termux packages
echo -e "\n\e[1;34mUpdating and upgrading Termux packages...\e[0m"
pkg update -y && pkg upgrade -y & spinner

# Install necessary repositories and packages
echo -e "\n\e[1;34mInstalling required repositories and packages...\e[0m"
pkg install -y x11-repo termux-x11-nightly tur-repo pulseaudio proot-distro wget git sox virglrenderer-android mesa zlib & spinner

# Configure PulseAudio settings
echo -e "\n\e[1;34mConfiguring PulseAudio settings...\e[0m"
cat << 'EOF' >> $PREFIX/etc/pulse/default.pa
load-module module-sles-sink
load-module module-sles-source
load-module module-null-sink sink_name=virtspk sink_properties=device.description=Virtual_Speaker
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF

#get a username and password from user
read -p "enter Your new USERNAME: " username
read -sp "enter password for new user: " password

# Install KOS Lite (Ubuntu) using proot-distro
echo -e "\n\e[1;34mInstalling KOS Lite distribution...\e[0m"
proot-distro install ubuntu & spinner

# Configure the KOS Lite environment
echo -e "\n\e[1;34mConfiguring KOS Lite environment...\e[0m"
proot-distro login ubuntu -- bash -c "


# Create a new user
useradd -m -G sudo -s /bin/bash $username
echo "$username:$password" | chpasswd

# Update and upgrade packages within KOS Lite
apt update -y && apt upgrade -y

# Install minimal KDE Plasma desktop environment 
apt install -y plasma-desktop kde-plasma-desktop

# Disable window compositor and desktop effects
mkdir -p /home/koslite/.config/
echo '[Compositing]' > /home/koslite/.config/kwinrc
echo 'Enabled=false' >> /home/koslite/.config/kwinrc
echo '[Effect-Blur]' >> /home/koslite/.config/kwinrc
echo 'Enabled=false' >> /home/koslite/.config/kwinrc
echo '[Effect-Login]' >> /home/koslite/.config/kwinrc
echo 'Enabled=false' >> /home/koslite/.config/kwinrc

# Install PulseAudio and related utilities
apt install -y pulseaudio pulseaudio-utils pavucontrol

# Install GPU acceleration tools
apt install -y mesa-utils

# Set environment variables for PulseAudio
echo 'export PULSE_SERVER=127.0.0.1' >> /home/koslite/.bashrc
echo 'export DISPLAY=:1' >> /home/koslite/.bashrc

# Install additional utilities
apt install -y nano htop easyeffects gimp 

# remove snap and ban snap and install firefox non snap ofcourse.
apt autoremove --purge snapd
apt-mark hold snapd
add-apt-repository ppa:mozillateam/ppa
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox
Pin: version 1:1snap*
Pin-Priority: -1
' | tee /etc/apt/preferences.d/mozilla-firefox
apt update
apt install firefox
# Clean up
apt autoremove -y && apt clean
" & spinner

# Create the start script in Termux
echo -e "\n\e[1;34mCreating start script for KOS Lite...\e[0m"
cat << 'EOF' > $PREFIX/bin/start-koslite
#!/bin/bash
source $PREFIX/etc/xuname
# Start KOS Lite with audio, microphone, and GPU support

# Start Termux X11

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :1 -ac &
# Start PulseAudio
pulseaudio --start --exit-idle-time=-1

# Start VirGL for GPU acceleration
virgl_test_server_android &

# Login to KOS Lite (Ubuntu) and start the desktop environment
proot-distro login ubuntu --user $username --shared-tmp -- bash -c "
    export DISPLAY=:1
    export PULSE_SERVER=127.0.0.1
    pactl load-module module-tunnel-source server=127.0.0.1
    startplasma-x11"
EOF
chmod +x $PREFIX/bin/start-koslite
#store username  to /etc/xuname
echo "username=$username" > $PREFIX/etc/xuname
echo installation is finished. now run "start-koslite" to start the os

