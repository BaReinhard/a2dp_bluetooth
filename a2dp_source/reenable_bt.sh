#!/bin/bash
currentDir=$(
  cd $(dirname "$0")
  pwd
) 
cd $currentDir
echo "Moving ${curentDir}/.asoundrc to ~/.asoundrc
mv ./.asoundrc ~/.asounrc
echo "Enabling bluez-udev"
sudo sed -i "s/#SUBSYSTEM==\"input\", GROUP=\"input\", MODE=\"0660\"/SUBSYSTEM==\"input\", GROUP=\"input\", MODE=\"0660\"/" /etc/udev/rules.d/99-com.rules
sudo sed -i "s/#KERNEL==\"input[0-9]*\", RUN+=\"/usr/local/bin/bluez-udev\"/KERNEL==\"input[0-9]*\", RUN+=\"/usr/local/bin/bluez-udev\"/" /etc/udev/rules.d/99-com.rules

echo "Complete...