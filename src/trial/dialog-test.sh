#!/bin/bash

# install
    step_1 () {
    exec 3>&1                   # open temporary file handle and redirect it to stdout
    items=$(dialog --checklist "Select what to install " 0 0 6 \
              1 "install guru-shell" on \
              2 "install guru-daemons" on \
              3 "desktop modifications" off \
              4 "install development tools" off \
              5 "install accesspoint server" off \
              6 "install file server" off \
              2>&1 1>&3)        # redirect stderr to stdout to catch output, redirect stdout to temporary file
    return_code=$?              # store result value
    exec 3>&-                   # close new file handle

    case $return_code in        # handle output
        1)      echo "canceled"                        ;;
        0)      echo "following modules selected:"
                for _item in $items ; do
                    case $_item in
                          1) install.guru-shell "$@"            ;;
                          2) install.guru-daemons "$@"          ;;
                          3) desktop.modifications "$@"         ;;
                          4) install.dev_tools "$@"             ;;
                          5) install.accesspoint_server "$@"    ;;
                          6) install.file_server "$@"           ;;
                         "") echo "empty item"                  ;;
                          *) echo "unknown item"
                    esac
                done                                   ;;

        255)    echo "escaped"                         ;;
        "")     echo "empty return code"               ;;
        *)      echo "unknown return code $return_code"
    esac
}

install.guru-shell () {
    echo "install.guru-shell"
}

install.guru-daemons () {
    echo "install.guru-daemons"
}

desktop.modifications () {
    echo "desktop.modifications"
}

install.dev_tools () {
    echo "install.dev_tools"
}

install.accesspoint_server () {
    echo "install.accesspoint_server"
}

install.file_server () {
    echo "install.file_server"
}

# Select what to install
step_1 "$@"

# install
step_2 "$@"