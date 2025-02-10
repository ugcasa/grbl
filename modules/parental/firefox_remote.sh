# install needed tools
command -v jq >/dev/null || sudo apt -y install jq
command -v lz4 >/dev/null || sudo apt -y install lz4
command -v lz4jsoncat >/dev/null || sudo apt -y install lz4json

# place for logs 
[[ -d $HOME/log ]] || mkdir $HOME/log

log_file="$HOME/log/firefox.log"
fox_folder="$HOME/.mozilla/firefox"

profiles=($(grep -e "Path" $fox_folder/profiles.ini | grep -v $fox_folder | cut -d"=" -f2-))

# select profile if mote than one
if [[ ${#profiles[@]} -gt 1 ]]; then
      echo "found more than one profiles"

      i=0
      for _profile in ${profiles[@]}; do 
            echo "$i: $_profile"
            ((i++))
      done

      read -p "select one: " answer

      if ! [[ ${profiles[$answer]} ]]; then 
            echo "no match '$answer'"
            exit 1
      fi

      profile=${profiles[$answer]}

else
      profile=$profiles
fi

echo "profile '$profile' selected"

# ubuntu 24.04
file="$fox_folder/$profile-release/sessionstore-backups/recovery.jsonlz4"

# older systems
[[ -f $file ]] || file="$fox_folder/$profile/sessionstore-backups/recovery.jsonlz4"

echo "$(date +%d:%m:%Y)"
logging=
last_urls=()
while true ; do 
      # get current entry
      # seems that there is quite delay in firefox 
      
      i=0;
      urls=()
      
      if ! [[ -f $file ]] ; then 
            echo "firefox not active"
            break 
      fi

      while true ; do
            url=$(lz4jsoncat $file | jq -r ".windows[$i].tabs | sort_by(.lastAccessed)[-1] | .entries[.index-1] | .url" 2>/dev/null)
            [[ $url ]] || break
            urls[$i]=$url 
            ((i++))
      done

      # print url of currently upen url if changed
      for (( i = 0; i < ${#urls[@]}; i++ )); do
            if [[ "${urls[$i]}" == "${last_urls[$i]}" ]] ; then 
                  continue
            else
                  string="$(date +%H:%M:%S) [$i] ${urls[$i]}"
                  echo "$string"
                  [[ $logging ]] && echo "$string" >>$log_file
                  last_urls[$i]=${urls[$i]}
            fi
      done

      # sleep a minute and check again or wait command
      read -p "[n|l|q]" -t 10 -n 1 -s key
      printf "\r"
      
      # command parser
      case $key in 
            q)
                  break 
                  ;;
            n)
                  last_urls=()
                  continue
                  ;;                   
            l)    if [[ $logging ]]; then 
                        echo "logging off"
                        logging= 
                  else
                        echo "logging started $(date +%d:%m:%Y)" >>$log_file
                        echo "logging to $log_file"
                        logging=true
                  fi

                  last_urls=()
                  continue
                  ;;
      esac
done