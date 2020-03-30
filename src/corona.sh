#!/bin/bash
# ujo.guru corona status viewer casa@ujo.guru 2020

source $GURU_BIN/lib/common.sh
source $GURU_BIN/lib/deco.sh
source $GURU_BIN/mount.sh

corona.main () {
    mount.system
    report_location="COVID-19/data"
    location="Finland"
    #corona.update

    case ${1,,} in
             status|all) corona.country_current_intrest ;;
                  short) corona.country_current_oneline "$2";;
           view|display) corona.display "$2" ;;
                    web) $GURU_BROWSER https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv ;;
                   help) corona.help ;;
                      *) corona.country_current_table "$1"
    esac
}


corona.help() {
    echo "-- guru tool-kit corona help -------------------------------------"
    printf "usage:\t\t %s corona [command|Country]\n" "$GURU_CALL"
    printf "commands:\n"
    printf " status|all          all interesting (hard coded) countries\n"
    printf " short <Country>     one line statistics\n"
    printf " view <interval>     table vie of all countries, updates \n"
    printf "                     hourly (or input in seconds)\n"
    printf " web                 open web view in source github page\n"
    printf "\nuse verbose flag '-v' to print headers.\n"
    printf "\nexample:\n"
    printf "\t %s -v corona status\n" "$GURU_CALL"
    printf "\t %s corona Estonia\n" "$GURU_CALL"
    printf "\t %s corona view\n" "$GURU_CALL"
    return 0
}


corona.update() {
    msg "upadating data... "
    local _clone_location="/tmp/guru/corona"
    source_file="cases_country.csv"

    if ! [ -d "$_clone_location" ]; then
            mkdir -p "$_clone_location"
            cd $_clone_location
            git clone -b web-data https://github.com/CSSEGISandData/COVID-19.git
        fi

    source_file=$_clone_location/$report_location/$source_file

    cd "$_clone_location/COVID-19"
    if git pull >/dev/null 2>&1 ; then
            UPDATED
            #return 0
        else
            FAILED "repository not found"
            return 10
        fi

    if [ -f "$source_file" ]; then
            return 0
        else
            FAILED "$source_file not found"
            return 10
        fi

}


corona.get_data () {
    local _location="$1"
    _data="$(cat $source_file | grep """$_location""")"
    _data="${_data//'  '/'_'}"
    _data="${_data//' '/'_'}"
    _data="$(echo $_data | column -t -s ',')"
    export data_list=($_data)
}


corona.country_current_table () {
    corona.update
    [ "$1" ] && location="$1"
    corona.get_data "$location"
    printf "%s \t%s %s \t%s \n" "Confirmed" "Deaths" "Recovered" "Active" | column -t -s $" "
    printf "%s \t\t%s \t%s \t\t%s \n" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}" "${data_list[7]}" | column -t -s $" "
}


corona.country_current_oneline () {
    [ "$1" ] && location="$1"
    _last_time="$GURU_TRACK/corona" ; [ -d "$_last_time" ] || mkdir "$_last_time"
    _last_time="$_last_time/$location.last" ; [ -f "$_last_time" ] || touch "$_last_time"

    corona.get_data "$location"

    declare -a _last_list=($(cat $_last_time))
    declare -a _current_list=(${data_list[4]} ${data_list[5]} ${data_list[6]})
    local _change=""

    printf "${NC}$location\t${CRY}%s\t${RED}%s\t${GRN}%s\t${NC}" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}"
    if ! ((_current_list[0]==_last_list[0])) ; then
            _change=$((_current_list[0]-_last_list[0]))

            ((_current_list[0]>_last_list[0])) && _sing="+" || _sing=""
            printf "${CRY}%s%s ${NC}" "$_sing" "$_change"
        fi

    if ! ((_current_list[1]==_last_list[1])) ; then
            _change=$((_current_list[1]-_last_list[1]))

            ((_current_list[1]>_last_list[1])) && _sing="+" || _sing=""
            printf "${RED}%s%s ${NC}" "$_sing" "$_change"
        fi

    if ! ((_current_list[2]==_last_list[2])) ; then
            _change=$((_current_list[2]-_last_list[2]))

            ((_current_list[2]>_last_list[2])) && _sing="+" || _sing=""
            printf "${GRN}%s%s ${NC}" "$_sing" "$_change"
        fi

    printf "\n"

    printf "%s %s %s"  "${_current_list[0]}" "${_current_list[1]}" "${_current_list[2]}" > "$_last_time"
}


corona.country_current_intrest () {
    corona.update
    local _country_list=("Finland" "Sweden" "Estonia" "Russia" "Norway" "Germany" "Spain" "France" "Italy" "Kingdom" "China" "US" )
    msg "${WHT}Country\tInfect\tDeath\tRecov\tchange${NC}\n"
    for _country in ${_country_list[@]}; do
            corona.country_current_oneline "$_country"
        done
}


corona.display () {
    # tput civis -- invisible
    local _sleep_time=3600 ; [ "$1" ] && _sleep_time=$1
    # trap '_pause' SIGINT
    while : ; do
            corona.country_current_intrest
            sleep "$_sleep_time"
            corona.update
        done
    # tput cnorm -- normal
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then        # if sourced only import functions
    corona.main $@
fi

#source_file="$(date --date="$_days days ago" +%m-%d-%Y).csv"
# local _header="$(head -n1 $source_file)"
# _header="${_header/" "/"_"}"                                                              # to avoid space slipt of headers
# _header="$(echo $_header | cut -d','  -f4-)"                                              # remove first two columns
# _header="$(echo $_header | column -t -s $',')"                                            # format as table
# export header_list=($_header)
# printf "%s \t%s %s \t%s \n" "${header_list[4]}" "${header_list[5]}" "${header_list[6]}" "${header_list[7]}" | column -t -s $" "