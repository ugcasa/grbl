

dialog.checklist () {
    # open temporary file handle and redirect it to stdout
    local _type="checklist" ; [[ "$1" ]] && _type="$1" ; shift
    local _x="50" ; [[ "$1" ]] && _x="$1" ; shift
    local _y="15" ; [[ "$1" ]] && _y="$1" ; shift

    _item_input=${@}
    _item_input=${_item_input//', '/';'}
    _item_input=${_item_input//' '/'_'}
    _item_input=${_item_input//';'/' '}

    # _item_list=(${_item_list[@]//', '/';'})
    # _item_list=(${_item_list[@]//' '/'_'})
    # _item_list=(${_item_list[@]//';'/' '})

    local _header="$(echo $_item_input | cut -f 1 -d ' ' )"
    declare -a _item_list=("$(echo $_item_input | cut -f 3-8 -d ' ' )")

    # echo ; echo "check: ${_item_list[@]}"

    local _i=0
    for _item in ${_item_list[@]} ; do
          # echo "item: $_item"
          _i=$((_i+1))
          _item_data=$(printf "%s %s %s off" "$_item_data" "$_i" "$_item" )
        done
    local _item_count="$((_i+1))"


    # echo ;set |grep '_type=\|_header=\|_y=\|_x=\|_item_count=\|_item_data='
       echo ; echo "--$_type" "$_header" "$_y" "$_x" "$_item_count" "$_item_data" #
    #exit 0
    exec 3>&1
    items=$(dialog --$_type --title "$_header" $_y $_x $_item_count "$_item_data" 2>&1 1>&3)
    selected_OK=$?
    exec 3>&-

    # handle output
    if [ $selected_OK = 0 ]; then
        echo "OK was selected."
        for item in $items; do
            echo "Item $item was selected."
            return 0
        done
    else
        echo "Cancel was selected."
        return 1
    fi
}

#          4 "install cloud server" off \
#          4 "install web server" off \
#          4 "install mqtt server" off \


dialog.checklist checklist 20 30 "Select what to install, install guru-shell, install guru-daemons, desktop modifications, install accesspoint server, install file server"