#!/bin/bash

### This should be run after LIGHTSHOWPI was installed, it will require a REBOOT afterwards.
### Must be run as non-root user

if [ $SUDO_USER ]; then echo "Must be run as non-root user";exit ; else user=`whoami`; fi
currentDir=$(
  cd $(dirname "$0")
  pwd
) 
AUTOCONNECT="AUTOCONNECT"
while [ $AUTOCONNECT != "y" ] && [ $AUTOCONNECT != "n" ];
do
	read -p "When a bluetooth device connects do you want move audio output to the bluetooth device? (y/n) : " AUTOCONNECT
done
START_PATH=$currentDir 
cd $START_PATH
export START_PATH
#--------------------------------------------------------------------
function tst {
    echo "===> Executing: $*"
    if ! $*; then
        echo "Exiting script due to error from: $*"
        exit 1
    fi	
}
#--------------------------------------------------------------------

# Install Pulse Audio & Bluez
tst sudo apt-get install bluez pulseaudio pulseaudio-module-bluetooth -y

# Install dbus for python
tst sudo apt-get install python-dbus -y

# Create users and priviliges for Bluez-Pulse Audio interaction - most should already exist
tst sudo addgroup --system pulse
tst sudo adduser --system --ingroup pulse --home /var/run/pulse pulse
tst sudo addgroup --system pulse-access
tst sudo adduser pulse audio
tst sudo adduser root pulse-access
tst sudo adduser pulse lp

tst sudo cp init.d/pulseaudio /etc/init.d
tst sudo chmod +x /etc/init.d/pulseaudio
tst sudo update-rc.d pulseaudio defaults

tst sudo cp init.d/bluetooth /etc/init.d
tst sudo chmod +x /etc/init.d/bluetooth
tst sudo update-rc.d bluetooth defaults

sudo apt-get install libtool intltool libsndfile-dev libcap-dev libjson0-dev libasound2-dev libavahi-client-dev libbluetooth-dev libglib2.0-dev libsamplerate0-dev libsbc-dev libspeexdsp-dev libssl-dev libtdb-dev libbluetooth-dev intltool -y

cd ~
git clone https://github.com/json-c/json-c.git
cd json-c
sh autogen.sh
./configure 
make
sudo make install
cd ~
sudo apt install autoconf autogen automake build-essential libasound2-dev libflac-dev libogg-dev libtool libvorbis-dev pkg-config python -y
git clone git://github.com/erikd/libsndfile.git
cd libsndfile
./autogen.sh
./configure --enable-werror
make
sudo make install

echo "===========Setting Bluetooth Policy========="
cat << EOT | sudo tee -a /etc/bluetooth/main.conf
[Policy]
AutoEnable=true
EOT



cd $START_PATH
echo "==============Compiling PulseAudio 6.0 from Source================="
cd ~
git clone --branch v6.0 https://github.com/pulseaudio/pulseaudio
cd pulseaudio
sudo ./bootstrap.sh
sudo make
sudo make install
sudo ldconfig
cd $START_PATH
tst sudo cp etc/pulse/daemon.conf /etc/pulse
tst sudo cp etc/pulse/system.pa /etc/pulse
tst sudo cp .asoundrc ~/.asoundrc
if [ $AUTOCONNECT = "y" ]; then
    echo "=====Installing Auto Connect bluez-udev====="
    tst sudo ./bt_on_connect.sh
fi

echo "============Bluetooth Configuration is Complete============="
echo "You will need to manually connect to your BT device via command line"
cat << EOT
sudo bluetoothctl
power on
agent on
default-agent
scan on
pair XX:XX:XX:XX:XX
trust XX:XX:XX:XX:XX
connect XX:XX:XX:XX
exit

# If you did not say 'y' to the the Bluetooth Autoconnection, you will need to perform the following:

# Your device should now be set as a pulseaudio sink
# This will need to be done manually each time you reconnect your BT device
# Until we create a udev rule to handle this
sudo pactl list sinks
sudo pactl list sink-inputs
sudo pactl move-sink-input $SINK_INPUT $SINK_OUTPUT

# Additionally you will need to set your bt device as a2dp sink
# This will need to be done manually each time you reconnect your BT device
# Until we create a udev rule to handle this
# Get Card Number
sudo pactl list cards
sudo pactl set-card-profile $CARD_NUMBER a2dp_sink

THIS IS STILL IN THE BETA PHASE and likely will require adjustment on timing to ensure music is synced with lights...
EOT
echo "Please reboot your system..."

