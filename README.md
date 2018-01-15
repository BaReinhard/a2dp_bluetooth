# a2dp_bluetooth

## a2dp_source

To connect a set of Bluetooth Headphones or Bluetooth Speakers to Raspbian Jessie, use the `configure` file, and run it.

**If running Raspbian Jessie**
```
git clone https://github.com/bareinhard/a2dp_bluetooth
cd a2dp_bluetooth/a2dp_source
./configure
```
**If running Ubuntu 14(May work on 16, haven't tested)**
```
git clone https://github.com/bareinhard/a2dp_bluetooth
git checkout ubuntu_14
cd a2dp_bluetooth/a2dp_source
./configure
```

**Pairing, Trusting, and Connecting**
```
sudo bluetoothctl
[bluetooth]# power on
[bluetooth]# agent on
[bluetooth]# default-agent
[bluetooth]# scan on
[bluetooth]# pair XX:XX:XX:XX:XX
[bluetooth]# trust XX:XX:XX:XX:XX
[bluetooth]# connect XX:XX:XX:XX:XX
[bluetooth]# exit
```
**Pairing on Ubunut**
***Simply go to System Settings, Bluetooth add device manually in GUI, after that each time your device turns on it will automatically connect and stream audio to the device***

**After the install, you will need to reboot and manually pair, trust, and connect your device only once. Going forward you will only need to turn on the bluetooth device and it will automatically connect**


