#!/bin/bash

# KOS Lite Installation Script
# License: GPL-3#!/bin/bash

# KOS Lite Installation Script
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

#!/bin/bash

# KOS Lite Installation Script
# License: GPL-3    local delay=0.1
    local spinstr='|/-\\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"

# Update and upgrade Termux packages
echo -e "\n\e[1;34mUpdating Termux packages...\e[0m"
pkg update -y && pkg upgrade -y & t_spinner

# Install required repositories and packages
echo -e "\n\e[1;34mInstalling required Termux packages...\e[0m"
pkg install -y x11-repo termux-x11-nightly tur-repo pulseaudio proot-distro wget git sox virglrenderer-android mesa zlib & t_spinner

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

# Update, upgrade and install desktop
apt update -y && apt upgrade -y
apt install -y plasma-desktop kde-plasma-desktop pulseaudio pulseaudio-utils pavucontrol mesa-utils nano htop easyeffects gimp

# Download and install Kainat OS packages
wge#!/bin/bash

# KOS Lite Installation Script
# License: GPL-3orge.net/projects/kainatos/files/main_arm/kainat-os-sources.deb/download"
dpkg -i /tmp/kainat-os-sources.deb || apt-get -f install -y
# Refresh package lists after adding new sources
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
    startplasma-x11
"
EOF
chmod +x $PREFIX/bin/start-koslite

echo "Installation complete. Run 'start-koslite' to launch."
