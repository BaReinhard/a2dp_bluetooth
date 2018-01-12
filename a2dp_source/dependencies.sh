#!/bin/bash

BT_DEPS="pulseaudio-module-bluetooth python-dbus libltdl-dev pulseaudio libtool intltool libsndfile-dev libcap-dev libasound2-dev libavahi-client-dev libbluetooth-dev libglib2.0-dev libsamplerate0-dev libsbc-dev libspeexdsp-dev libssl-dev libtdb-dev libbluetooth-dev intltool autoconf autogen automake build-essential libasound2-dev libflac-dev libogg-dev libtool libvorbis-dev pkg-config python"

JESSIE_BT_DEPS="libjson0-dev"

STRETCH_BT_DEPS="libjson-c-dev autopoint"

INSTALL_COMMAND='sudo apt-get -y install'

A2DPSOURCE_FILES="/usr/local/bin/bluez-udev /etc/init.d/bluetooth /etc/init.d/pulseaudio"
