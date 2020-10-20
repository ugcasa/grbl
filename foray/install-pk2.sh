#!/bin/bash

read -p "install programmer? [Y/n] : " -i Y install
if ! [  $install == "y"  ]; then
     exit 1
fi

install_found(){

    read -p "allready installed.. force re-install? : " install
    if ! [  $install == "y"  ]; then
         exit 1
    fi
}

quits() {
    read -p "compilation fucked up, press any key to exit"
    exit 123
}

pk2cmd -?v && install_found

source="http://www.microchip.com/forums/download.axd?file=0;749972"
echo "source: $source"
read -p "me open firefox, you download to ~/Downloads, right?"

[ -d $HOME/apps ] || mkdir $HOME/apps
if [ ! -f  ~/Downloads/PK2DeviceFile.zip ]; then
    firefox "$source"
    read -p "waiting until downlaod ready, continue by pressing anykey "
fi

cd $HOME/apps
sudo apt install -y g++ libusb-dev
[ -f wget PICkit2_PK2CMD_WIN32_SourceV1-21_RC1.zip ] || wget http://ww1.microchip.com/downloads/en/DeviceDoc/PICkit2_PK2CMD_WIN32_SourceV1-21_RC1.zip
unzip PICkit2_PK2CMD_WIN32_SourceV1-21_RC1.zip
cd pk2cmd/pk2cmd
make linux || quits
sudo rm /usr/share/pk2 || echo "Installation not found" && echo "OK"
sudo cp pk2cmd /usr/local/bin/
[ -f  ~/Downloads/PK2DeviceFile.zip ] && unzip ~/Downloads/PK2DeviceFile.zip
[ -d /usr/share/pk2 ] || sudo mkdir /usr/share/pk2
sudo mv PK2DeviceFile.dat /usr/share/pk2
sudo chmod u+s /usr/local/bin/pk2cmd

# export PATH=$PATH:/usr/share/pk2
# source ~/.bashrc

# cleaning
cd $HOME/apps
rm -rf pk2cmd PICkit2_PK2CMD_WIN32_SourceV1-21_RC1.zip  ReadMe.txt

# Testing
cd
pk2cmd -?v && echo "installation OK" || echo "Installation failed"

read -p "Install ready, press any key to exit"
