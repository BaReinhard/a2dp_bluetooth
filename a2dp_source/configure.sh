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
A2DPSOURCE_PATH=$currentDir 
A2DPSOURCE_BACKUP_PATH="$A2DPSOURCE_PATH/backup_files"
cd $A2DPSOURCE_PATH
export A2DPSOURCE_PATH
export A2DPSOURCE_BACKUP_PATH
source functions.sh
source dependencies.sh
apt_update
apt_upgrade



VERSION=`cat /etc/os-release | grep VERSION= | head -1 | sed "s/VERSION=//"`


if [ "$VERSION" = "\"8 (jessie)\"" ]
then
    log "Raspbian Jessie Found"
    for _dep in ${JESSIE_BT_DEPS[@]}; do
        apt-get install $_dep -y;
    done
elif [ "$VERSION" = "\"9 (stretch)\"" ]
then
    log "Raspbian Stretch Found"
    for _dep in ${STRETCH_BT_DEPS[@]}; do
        apt_install $_dep;
    done
else
    log "You are running an unsupported VERSION of RASPBIAN"
    log "Some features may not work as expected"
fi
for _dep in ${BT_DEPS[@]}; do
    apt_install $_dep;
done

# Create users and priviliges for Bluez-Pulse Audio interaction - most should already exist
exc sudo addgroup --system pulse
exc sudo adduser --system --ingroup pulse --home /var/run/pulse pulse
exc sudo addgroup --system pulse-access
exc sudo adduser pulse audio
exc sudo adduser root pulse-access
exc sudo adduser pulse lp

save_original /etc/init.d/pulseaudio
exc sudo cp init.d/pulseaudio /etc/init.d
exc sudo chmod +x /etc/init.d/pulseaudio
exc sudo update-rc.d pulseaudio defaults

save_original /etc/init.d/bluetooth
exc sudo cp init.d/bluetooth /etc/init.d
exc sudo chmod +x /etc/init.d/bluetooth
exc sudo update-rc.d bluetooth defaults

if [ -d "/etc/pulse" ]
then
  PA_FILES=`ls /etc/pulse`
  for _file in ${PA_FILES[@]}; do
        if [ -e $_file ]; then 
            if [ -d $_file ]; then 
               continue
            else
               save_original $_file
            fi
        fi
  done
else
  exc sudo mkdir /etc/pulse  
fi



save_original /etc/bluetooth/main.conf
echo "===========Setting Bluetooth Policy========="
cat << EOT | sudo tee -a /etc/bluetooth/main.conf
[Policy]
AutoEnable=true
EOT



cd $A2DPSOURCE_PATH
if [ "$VERSION" = "\"8 (jessie)\"" ]
  then
      log "Raspbian Jessie Found"
      log "Pulseaudio Version Below v6.0, upgrading from source"
      exc cd ~
        remove_dir json-c
        exc git clone https://github.com/json-c/json-c.git
        exc cd json-c
        exc sh autogen.sh
        exc ./configure 
        exc make
        exc sudo make install
        cd ~
        remove_dir libsndfile
        exc git clone git://github.com/erikd/libsndfile.git
        exc cd libsndfile
        exc ./autogen.sh
        exc ./configure --enable-werror
        exc make
        exc sudo make install
      exc remove_dir /etc/pulsebackup
      exc sudo mkdir /etc/pulsebackup
      exc sudo cp /etc/pulse/* /etc/pulsebackup/
      exc cd ~
      exc remove_dir pulseaudio
      exc git clone --branch v6.0 https://github.com/pulseaudio/pulseaudio
      exc cd pulseaudio
      exc sudo ./bootstrap.sh
      exc sudo make
      exc sudo make install
      exc sudo ldconfig
      exc sudo cp /etc/pulsebackup/* /etc/pulse
  elif [ "$VERSION" = "\"9 (stretch)\"" ]
  then
      log "Raspbian Stretch Found"
      log "Pulseaudio Version Already Exceeds v6.0"
      log "Patching System Daemon"
      exc sudo sed -i "s+DAEMON=/usr/local/bin/pulseaudio+DAEMON=/usr/bin/pulseaudio+" /etc/init.d/pulseaudio 
      exc sudo systemctl daemon-reload
      exc sudo cp .asoundrc ~/.asoundrc
  else
      log "You are running an unsupported VERSION of RASPBIAN"
  fi

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

