#!/bin/bash
# guru-cli cad software installer and configurator


cad.main () {


}

cad.run_rc () {

    export blender_folder="$GURU_APP/blender"

}


cad.make_rc () {


}


cad.install_unity() {

    # unity hub (is this really needed?)
    sudo sh -c 'echo "deb https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list'
    wget -qO - https://hub.unity3d.com/linux/keys/public | sudo apt-key add -
    sudo apt update
    sudo apt-get install unityhub
    # download and unxip unity 3d

    # sudo apt-get remove unityhub
    # https://unity.com/releases/editor/whats-new/2022.2.1
}



cad.install_blender () {

    # [[ $blender_folder ]] || mkdir -p $blender_folder
    # cd $blender_folder
    # wget https://builder.blender.org/download/daily/blender-3.3.2-stable+v33.bd3a7b41e2b3-linux.x86_64-release.tar.xz
    # skipped: unable to know current version

    # build from source
    # https://ubuntuhandbook.org/index.php/2021/10/install-blender-ubuntu-complete-guide/
    # skipped: may not work, takes time to test and may need multiple requirement install script runs

    # from universe: +easy +multi arch -very old -no updates
    # skipped: old, no update anymore
    # sudo apt update && sudo apt install blender

    # trying to build it
    # page=$(curl https://download.blender.org/source/ | tr -s ' ')

    # declare -a zips=()
    # ifs=$IFS
    # (
    # IFS="$(printf '\n')"
    # echo -n "$IFS" | od -t x1
    # # list=$(echo ${page[@]} | sed -e 's/<\/b>/-/g' -e 's/<[^>]*>//g')
    # for line in $(echo ${page[@]} | sed -e 's/<\/b>/-/g' -e 's/<[^>]*>//g'blen) ;do

    #         echo $line | grep -v 'md5' | cut -d' ' -f1 >>/tmp/list
    #         zips+=("$(echo $line | grep -v 'md5' | cut -d' ' -f1 )" )


    #     # zips+=("$(echo $line | grep -v 'md5' | cut -d' ' -f1)")
    #     # versions+=()
    #     done
    # )
    # IFS=$ifs

    # for zip in ${zips[@]}; do
    #     echo $zip
    # done
    # echo $page
    # versions=
    # url=
    # fuck it..

    # lets go with old version and upgrade it later by blender it self (if it's possible)
    # only version to get from apt is v2.82.7 WAY too old. lts stable is 2.93.13 and there is even stable 3.3.2 and 3.4.1 and alpha 3.5.0!
    # current recommended if 3.4.1
    # sudo apt update && sudo apt install blender
    # # "there is no in-software option to update" fuck..
    # # fuck this too then
    # sudo apt purge blender -y
    # sudo apt autoremove -y

    # the best method
    # download and unzip Blender
    gr.msg "Download from https://www.blender.org/download/ "
    
}


cad.install_specemouse () {
    sudo apt-get update

    # libraries for spacemouse
    sudo apt-get install libxm4 -f
    # download setup tool (and daemon)
    wget https://download.3dconnexion.com/drivers/linux/3dxware-linux-v1-8-0.x86_64.tar.gz
    tar –xvzf 3dxware-linux-v1-8-0.x86_64.tar.gz
    sudo ./install-3dxunix.sh linux

    # run setup tool (and exit)
    sudo /etc/3DxWare/daemon/3dxsrv -d usb

    # setup in blender
    # https://www.youtube.com/watch?v=bJ2aJ8rlgKg

    # driver for spacemouse for blender / unity support
    # https://robots.uc3m.es/installation-guides/install-spacenav.html
    sudo apt-get install libspnav-dev spacenavd -f

    # https://wiki.archlinux.org/title/3D_Mouse
    # http://www.spacemice.org/index.php?title=Blender
    # https://spacenav.sourceforge.net/
    # https://spacenav.sourceforge.net/man_libspnav/

}