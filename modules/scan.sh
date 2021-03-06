#!/bin/bash
# guru shell scanner wrappers


scan.main () {
    local _cmd=$1 ; shift
    case $_cmd in
            check|receipt|invoice|install|remove|help)
                    scan.$_cmd $@                   ; return $? ;;
            *)      gmsg "scan: unknown command"    ; return 1  ;;
        esac
}


scan.help () {
    gmsg -v1 -c white "guru-client scan help "
    gmsg -v2
    gmsg -v0 "usage:    $GURU_CALL scan [receipt|invoice|install] "
    gmsg -v2
    gmsg -v1 "receipt   scan receipt size grayscale                 "
    gmsg -v1 "invoice   scan receipt A4 size optimized grayscale    "
    gmsg -v1 "install   install Epson DS30 driver and applications  "
    gmsg -v1 "fix       to to fix access limitation problem         "
    gmsg -v1
    gmsg -v1 "example:  $GURU_CALL scan receipt motonet-tools "
}


scan.install () {
    # http://download.ebz.epson.net/man/linux/iscan_e.html

    if [[ -f /usr/bin/iscan ]] ; then
            gmsg "installed, use force to reinstall"
            return 0
        fi

    # check os type
    if [[ `uname -o` != "GNU/Linux" ]] ; then
            gmsg -c red "non comptible plaform $(uname -o)"
            return 100
        fi

    source /etc/os-release
    ver="3.63.0" ; [[ $1 ]] && ver="$1"
    arch="x64"
    source="https://download2.ebz.epson.net/imagescanv3/linuxmint/lts1/deb/x64"
    dep_file="imagescan-bundle-${ID}-${VERSION_ID}-${ver}.${arch}.deb"
    gz_file="${dep_file}.tar.gz"
    gmsg -v3 -c pink "${gz_file}"
    gmsg -v3 -c deep_pink "${source}/${gz_file}"

    case $ID in
            linuxmint|ubuntu|debian)

                gmsg -v1 -c white "downloading.."
                cd /tmp
                wget "${source}/${gz_file}" || gmsg -c red -x 101 "source location not found $source/${gz_file}"

                gmsg -v1 -c white "decompressing.."
                [[ -f $gz_file ]] || gmsg -c red -x 102 "source ${gz_file} not found"
                tar -xvf $gz_file || gmsg -c red -x 103 "unable to extract ${gz_file}"
                cd $dep_file || gmsg -c red -x 104 "cannot enter folder ${dep_file}"

                gmsg -v1 -c white "running installer.."
                ./install.sh
                gmsg -v3 -c deep_pink "$?"

                gmsg -v1 -c green "install success"
                gmsg -v2 -c dark_grey "cleaning up.."
                cd ..
                rm -rf imagescan-bundle-linuxmint*

                gmsg -v1 -c white "installing requirements.. "

                #[[ $ID != "debian" ]] && sudo add-apt-repository ppa:rolfbensch/sane-git
                sudo apt update
                sudo apt install -y xsane imagemagick gocr || gmsg -c red -x 105 "apt install error"

                gmsg -c green "done"
                ;;

            *)
                gmsg -c yellow "unknown distro '$$ID'. pls refer $GURU_BIN/install.sh function scan.install :~50"
                return 106
                ;;
        esac

        # setup installation
        gmsg -v1 -c white "modifying config files.. "

        # case: scanner not found
        local rule_file="/etc/udev/rules.d/79-udev-epson.rules"
        gmsg -v2 -c pink "$rule_file"
        [[ -f "$rule_file" ]] && sudo rm $rule_file

        #echo 'ATTR{idVendor}="0x04b8", ATTR{idProduct}="0x012f", SYMLINK+="scan-epson", MODE="0666", OWNER="$USER", GROUP="scanner"' \| sudo tee --append $rule_file
        echo 'SUBSYSTEM="usb_device", ACTION="add", GOTO="epson_rules_end"' | sudo tee --append  $rule_file
        echo 'ATTRS{idVendor}="0x04b8", ATTR{idProduct}="0x0147", SYMLINK+="scan-epson", MODE="0666", OWNER="$USER", GROUP="scanner", ENV{libsane_matched}="yes"' \
            | sudo tee --append $rule_file
        echo 'LABEL="epson_rules_end"' | sudo tee --append $rule_file

        # case: parmission error fix
        sudo sed -i -e 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/g' \
            /etc/ImageMagick-6/policy.xml

        # case: scanimage: no SANE devices found fix
        # local rule_file="/etc/udev/rules.d/40-libsane.rules"
        # gmsg -v2 -c pink "$rule_file"
        # [[ -f "$rule_file" ]] && sudo rm $rule_file
        # echo 'ATTRS{idVendor}=="0x04b8", ATTRS{idProduct}=="0x0147", ENV{libsane_matched}="yes"' | sudo tee --append $rule_file

        sudo udevadm control --reload-rules && udevadm trigger

        # test
        gmsg -c white "testing.. "
        scan.check
        return $?
}


scan.check () {
    gmsg -n -v1 "checking device.. "
    local scanner_type="EPSON DS-30"

    if ! sudo sane-find-scanner | grep "$scanner_type" >/dev/null ; then
            gmsg -c red "sane cannot find $scanner_type"
            return 100
        fi

    if sudo sudo scanimage -L | grep "No scanners" >/dev/null ; then
            gmsg -c red -x 106 "no sane support for $scanner_type"
            return 101
        fi

    gmsg -v1 -c green "$scanner_type found"
    return 0

}

scan.remove () {

    sudo apt install -y xsane imagemagick gocr || gmsg -c red -x 110 "apt error"
    sudo rm /etc/udev/rules.d/40-libsane.rules
    sudo rm $/etc/udev/rules.d/79-udev-epson.rules
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
    gmsg -v2 -c black "${FUNCTION[0]} TBD"
    # scanimage -x 205 -y 292 --mode Gray --format=pgm -v >image$stamp.pgm
    # convert image$stamp.pgm -crop 2416x4338+55+120 scan_$stamp-$page.pgm
    # #gocr -i scan_$stamp-$page.pgm -f UTF8 -v >>archive$stamp.txt
    # mogrify -resize 33% scan_$stamp-$page.pgm
    # echo "scan_$stamp-$page.pgm" >>tocompile$stamp
}


scan.install () {
    scanimage -V >/dev/null 2>&1 || scan.install
    convert -version >/dev/null || sudo sudo apt install imagemagick-6.q16
    #gocr >/dev/null || sudo apt-get install -y gocr
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    scan.main $@
fi