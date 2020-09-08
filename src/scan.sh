#!/bin/bash
# guru shell scanner wrappers

scanimage -V >/dev/null 2>&1 || scan.install
convert -version >/dev/null || sudo sudo apt install imagemagick-6.q16
#gocr >/dev/null || sudo apt-get install -y gocr


scan.main () {
    local _cmd=$1 ; shift
    case $_cmd in
            receipt|invoice|install|help)
                    scan.$_cmd $@                   ; return $? ;;
            *)      gmsg "scan: unknown command"    ; return 1  ;;
        esac
}


scan.help () {
    echo "-- guru tool-kit scan help ---------------------------------"
    printf "usage: %s scan command options \ncommands:              \n" "$GURU_CALL"
    printf "receipt   scan receipt size grayscale                 \n"
    printf "invoice   scan receipt A4 size optimized grayscale    \n"
    printf "install   install Epson DS30 driver and applications  \n"
    printf "fix       to to fix access limitation problem         \n"
    printf "example:\n\t  %s scan receipt motonet-tools          \n" "$GURU_CALL"
}


scan.install () {
    # http://download.ebz.epson.net/man/linux/iscan_e.html
    read -p "installing EPSON DS30 driver, continue by anykey, ctrl-c to cancel :" null

    if [[ "$(ls /usr/bin/iscan >/dev/null)" -ne 0 ]]; then
        cd /tmp
        wget https://download2.ebz.epson.net/imagescanv3/linuxmint/lts1/deb/x64/imagescan-bundle-linuxmint-19-3.59.2.x64.deb.tar.gz || return 101
        tar -xvf  imagescan-bundle-linuxmint-19-3.59.2.x64.deb.tar.gz || return 102
        cd imagescan-bundle-linuxmint-19-3.59.2.x64.deb || return 102
        sh install.sh
        cd ..
        rm imagescan-bundle-linuxmint-19-3.59.2.x64.deb.tar.gz*
        rm -rf imagescan-bundle-linuxmint-19-3.59.2.x64.deb
        sudo apt update
        sudo apt install xsane imagemagick gocr || return 103
        # Test
        sudo sane-find-scanner | grep "EPSON DS-30" && echo "Scanner found" || return 104

        local _file=/etc/udev/rules.d/79-udev-epson.rules
        if [[ -f "$_file" ]] ; then
            echo "$_file exist"
            #sudo rm $_file?
        else
            echo 'SUBSYSTEM="usb_device", ACTION="add", GOTO="epson_rules_end"' | sudo tee --append  $_file
            echo 'ATTR{idVendor}="0x04b8", ATTR{idProduct}="0x012f", SYMLINK+="scan-epson", MODE="0666", OWNER="$USER", GROUP="scanner"' | sudo tee --append $_file
            echo 'LABEL="epson_rules_end"' | sudo tee --append $_file
        fi
        read -p "modifying config files continue enter ctrl-c cancel" null
        sudo sed -i -e 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/g' /etc/ImageMagick-6/policy.xml
    fi
}


scan.fix () {
    # imagemagick eliminating all usage restrictions
    sudo mv /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xmlout || return 101
    # to revert to the original situation, rename back to the original
}


scan.receipt() {
    # scan receipt size archive material
    local _temp=/tmp/guru
    local _name="scan"
    local _stamp=$(date +%s)
    local _target_folder="$GURU_LOCAL_ACCOUNTING/$(date +%Y)/$GURU_LOCAL_RECEIPTS"
    [[ "$1" ]] && _name=$1 || read -p "_name for receipt: " _name
    local _target_file=$_name-$(date -d now +$GURU_FORMAT_FILE_DATE).pdf

    # scan file
    gmsg "place the receipt to scanner feeder and press push-button when green LED lights up"
    scanimage -x 75 -y 300 --mode Gray --format=pgm -v >"$_temp/scan_$_stamp.pgm" || return 101
    while [ ! -f "$_temp/scan_$_stamp.pgm" ] ; do  printf "." ; sleep 2 ; done ; echo

    # modify file
    mogrify -resize 33% "$_temp/scan_$_stamp.pgm" || return 102
    convert "$_temp/scan_$_stamp.pgm" "$_temp/scan_$_stamp.pdf" || return 103

    # move to location
    [[ -d "$_target_folder" ]] || mkdir -p "$_target_folder"
    cp "$_temp/scan_$_stamp.pdf" "$_target_folder/$_target_file" || return 104
    gmsg "scanned to $_target_folder/$_target_file"
    echo "$_target_folder/$_target_file" | xclip

    # clean up
    [[ -f "$_temp/scan_$_stamp*" ]] && rm "$_temp/scan_$_stamp*"
    return 0
}


scan.invoice () {
    echo "TBD"
    # scanimage -x 205 -y 292 --mode Gray --format=pgm -v >image$stamp.pgm
    # convert image$stamp.pgm -crop 2416x4338+55+120 scan_$stamp-$page.pgm
    # #gocr -i scan_$stamp-$page.pgm -f UTF8 -v >>archive$stamp.txt
    # mogrify -resize 33% scan_$stamp-$page.pgm
    # echo "scan_$stamp-$page.pgm" >>tocompile$stamp
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    scan.main $@
fi