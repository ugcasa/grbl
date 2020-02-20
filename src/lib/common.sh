# guru tool-kit common functions for installer casa@ujo.guru 2020

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

# compatible_ubuntu(){
#     # check that current os is ubuntu

#     . /etc/os-release

#     case "$ID" in

#         linuxmint)
            
#             echo "Not valid method for $PRETTY_NAME installations"; 
#             if ! [ "$ID_LIKE" == "ubuntu" ]; then 
#                 return 255          # no go 
#             fi
            
#             read -r -p "it is $ID_LIKE dow, you wanna try? y/n: " answer
#             if [ "${answer^^}" == "Y" ]; then                 
#                 return 0            # go!
#             fi
            
#             return 255              # no go
#             ;;
        
#         ubuntu)
            
#             return 0                # go!
#             ;;
        
#         *)
#             echo "Non compatible installation $PRETTY_NAME, do not like to break anything, returning.."
#             return 255              # no go
#     esac        
#     return 255                      # no go
# }