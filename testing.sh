#!/usr/bin/env bash

# KOS Lite Installation Script
# License: GPL-3.0
# Developer: Kainat Quaderee

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\\'
    while ps -p "$pid" &>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%$temp}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# 1. Update Termux packages
echo -e "\n\e[1;34mUpdating Termux packages...\e[0m"
pkg update -y && pkg upgrade -y & spinner

# 2. Install Termux repos and packages
echo -e "\n\e[1;34mInstalling Termux packages...\e[0m"
pkg install -y x11-repo termux-x11-nightly tur-repo pulseaudio proot-distro wget git sox virglrenderer-android mesa zlib & spinner

# 3. Configure PulseAudio
echo -e "\n\e[1;34mConfiguring PulseAudio...\e[0m"
cat << 'EOF' >> "$PREFIX/etc/pulse/default.pa"
load-module module-sles-sink
load-module module-sles-source
load-module module-null-sink sink_name=virtspk sink_properties=device.description=Virtual_Speaker
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF

# 4. Prompt for user credentials
read -p "Enter new USERNAME: " username
read -sp "Enter password: " password
echo

# 5. Install Debian via proot-distro
echo -e "\n\e[1;34mInstalling Debian distribution...\e[0m"
proot-distro install debian & spinner

# 6. Configure Debian environment
echo -e "\n\e[1;34mConfiguring Debian environment...\e[0m"
proot-distro login debian -- bash -eux << 'DEBIAN_SETUP'

# Create user and grant sudo
useradd -m -G sudo -s /bin/bash "$username"
echo "$username:$password" | chpasswd
echo "$username ALL=(ALL:ALL) ALL" > /etc/sudoers.d/${username}-sudoers

# Update, upgrade and install desktop
apt update -y && apt upgrade -y
apt install -y plasma-desktop kde-plasma-desktop pulseaudio pulseaudio-utils pavucontrol mesa-utils nano htop easyeffects gimp

# Download and install Kainat OS packages
download_url="https://forge.net/projects/kainatos/files/main_arm/kainat-os-sources.deb/download"
wget -O /tmp/kainat-os-sources.deb "$download_url"
dpkg -i /tmp/kainat-os-sources.deb || apt-get -f install -y
apt-get update -y
apt install -y kainat-os-core

# Cleanup
autoremove -y && apt clean
DEBIAN_SETUP & spinner

# 7. Build and install box64, box86, Wine
echo -e "\n\e[1;34mInstalling box64, box86, and Wine...\e[0m"
proot-distro login debian -- bash -eux << 'EMULATOR_SETUP'

# Install build dependencies and i386 libs
dpkg --add-architecture i386
apt update -y
apt install -y cmake git build-essential gcc g++ python3 \
               libc6:i386 libstdc++6:i386 libx11-6:i386 libxext6:i386 \
               libgl1-mesa-glx:i386 libfreetype6:i386 libglu1-mesa:i386 mesa-utils wget

# Build box64
cd /opt
git clone https://github.com/ptitSeb/box64.git
cd box64
mkdir build && cd build
cmake .. -DRUN_FROM_BUILD=1
make -j"$(nproc)"
ln -sf /opt/box64/build/box64 /usr/local/bin/box64

# Build box86
cd /opt
git clone https://github.com/ptitSeb/box86.git
cd box86
mkdir build && cd build
cmake .. -DRUN_FROM_BUILD=1
make -j"$(nproc)"
ln -sf /opt/box86/build/box86 /usr/local/bin/box86

# Install Wine (32-bit)
apt install -y wine32 winetricks

# Environment wrappers
echo 'export BOX64_LOG=1' >> /etc/profile
echo 'export BOX86_LOG=1' >> /etc/profile
echo 'alias wine="box86 wine"' >> /etc/profile
EMULATOR_SETUP & spinner

# 8. Create launch script
echo -e "\n\e[1;34mCreating start script...\e[0m"
cat << 'EOF' > "$PREFIX/bin/start-koslite"
#!/usr/bin/env bash

# Start Termux X11
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
XDG_RUNTIME_DIR="${TMPDIR}" termux-x11 :1 -ac &

# Start PulseAudio
pulseaudio --start --exit-idle-time=-1

# Start VirGL server
virgl_test_server_android &

# Launch KDE in Debian
proot-distro login --shared-tmp --user "$username" debian -- bash -lc '
    export DISPLAY=:1
    export PULSE_SERVER=127.0.0.1
    pactl load-module module-tunnel-source server=127.0.0.1
    startplasma-x11
'
EOF
chmod +x "$PREFIX/bin/start-koslite"

# Done
echo -e "\n\e[1;32mInstallation complete. Run 'start-koslite' to launch.\e[0m"
