#!/bin/bash
# Should be run as root

#--------------------------------------------------------------------
function tst {
    echo "===> Executing: $*"
    if ! $*; then
        echo "Exiting script due to error from: $*"
        exit 1
    fi	
}
#--------------------------------------------------------------------
source functions.sh
source dependencies.sh
if [ -f /etc/udev/rules.d/99-com.rules ]; then

sudo patch /etc/udev/rules.d/99-com.rules << EOT
***************
*** 1 ****
--- 1,2 ----
  SUBSYSTEM=="input", GROUP="input", MODE="0660"
+ KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluez-udev"
EOT

else

tst sudo touch /etc/udev/rules.d/99-com.rules
tst sudo chmod 666 /etc/udev/rules.d/99-com.rules
sudo cat  << EOT > /etc/udev/rules.d/99-input.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluez-udev"
EOT

fi
VERSION=`cat /etc/os-release | grep VERSION= | head -1 | sed "s/VERSION=//"`

if [ "$VERSION" = "\"8 (jessie)\"" ]
then
    exc sudo cp usr/local/bin/bluez-udev /usr/local/bin/bluez-udev
elif [ "$VERSION" = "\"9 (stretch)\"" ]
then
    exc sudo cp usr/local/bin/bluez-udev.stretch /usr/local/bin/bluez-udev
else
    log "You are running an unsupported VERSION of RASPBIAN"
    log "Some features may not work as expected"
fi
sudo chmod +x /usr/local/bin/bluez-udev
