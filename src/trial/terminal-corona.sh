#!/bin/bash
# ujo.guru corona status viewer casa@ujo.guru 2020

# decorations from deco.sh for standalone
export RED='\033[0;31m'
export GRN='\033[0;32m'
export NC='\033[0m'
export UPDATED="${GRN}UPDATED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"

FAILED () { [ "$1" ] && printf "${WHT}$1:${NC} $FAILED" || printf "$FAILED"; }
UPDATED () { [ "$1" ] && printf "$1: $UPDATED" || printf "$UPDATED"; }

corona.main () {
    location="Finland"
    report_location="COVID-19/data"     # in the repository (donn't change)
    country_list=("Finland" "Sweden" "Estonia" "Russia" "Norway" "Germany" "Spain" "France" "Italy" "Kingdom" "China" "US" )

    case ${1,,} in
             status|all) corona.country_current_intrest ;;
                  short) corona.country_current_oneline "$2";;
                  table) corona.country_current_table ;;
           view|display) corona.display "$2" ;;
                    web) firefox https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv ;;
                   help) corona.help ;;
                      *) corona.country_current_intrest
    esac
}


corona.help() {
    echo "-- ujo.guru terminal-corona help -----------------------------------"
    printf "usage:\t\t terminal-corona [command|Country] \n"
    printf "commands:\n"
    printf " status|all          all interesting (hard coded) countries \n"
    printf " short <Country>     one line statistics \n"
    printf " web                 open web view in source github page \n"
    printf " view <interval>     table vie of all countries, updates \n"
    printf "                     hourly (or input amount of seconds) \n"
    printf " table               some kind of table view \n"

    printf "\nuse verbose flag '-v' to print headers. \n"
    printf "\nexample:\n"
    printf "\t terminal-corona status \n"
    printf "\t terminal-corona Estonia \n"
    printf "\t terminal-corona view 10 \n"
    return 0
}


corona.update() {
    printf "upadating data... "
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
    _last_time="$HOME/corona" ; [ -d "$_last_time" ] || mkdir "$_last_time"
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
    printf "${WHT}Country\tInfect\tDeath\tRecov\tChange ${NC}(since last check)\n"
    for _country in ${country_list[@]}; do
            corona.country_current_oneline "$_country"
        done
}


corona.display () {
    local _sleep_time=3600 ; [ "$1" ] && _sleep_time=$1
    while : ; do
            corona.country_current_intrest
            sleep "$_sleep_time"
            corona.update
        done
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    corona.main $@
    exit 0
fi

