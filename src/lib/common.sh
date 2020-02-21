# guru tool-kit common functions for installer casa@ujo.guru 2020
# echo "common.sh: included by: $0"

compatible_with(){
    # check that current os is compatible with input [ID] {VERSION_ID}
    
        . /etc/os-release
        #[ "$ID" == "$1" ] && return 0 || return 255
        if [ "$ID" == "$1" ]; then 
            if [ "$VERSION_ID" == "$2" ] || ! [ "$2" ]; then 
                return 0 
            else
                echo "${0} is not compatible with $NAME $VERSION_ID, expecting $2 "
                return 255
            fi
        else
            echo "${0} is not compatible with $PRETTY_NAME, expecting $1 $2"
            return 255
        fi
}


check_distro() {
    # returns least some standasrt type linux distributuin name
    . /etc/os-release
    echo "$ID"
    return 0

}
