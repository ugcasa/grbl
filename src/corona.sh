

source $GURU_BIN/lib/common.sh
source $GURU_BIN/lib/deco.sh

corona.main () {

    local _days=1 ; [ "$2" ] && _days="$2"

    #source_file="$(date --date="$_days days ago" +%m-%d-%Y).csv"
    source_file="cases_country.csv"
    report_location="COVID-19/data"
    location="Finland"

    corona.update

    case ${1,,} in
        all)  corona.print_country_intrest ;;
         uk)  corona.print_country_table "United_Kingdom" ;;
      short)  corona.print_country_oneline "$2";;
          *)  corona.print_country_table "$1"

    esac
}


corona.update() {

    local _clone_location="/tmp/guru/corona"
    msg "upadating data... "
    if ! [ -d "$_clone_location" ]; then
            mkdir -p "$_clone_location"
        fi

    source_file=$_clone_location/$report_location/$source_file

    cd $_clone_location
    if ! [ -f "$source_file" ]; then
            rm -rf "$_clone_location/COVID-19"
            if git clone -b web-data https://github.com/CSSEGISandData/COVID-19.git; then
                    echo "SUCCESS"
                    return 0
                else
                    echo "FAILED $source_file not found"
                    return 10
                fi
        fi

    if [ -f "$source_file" ]; then
            return 0
        else
            echo "FAILED $source_file not found"
            return 10
        fi
        exit 0

}

corona.header () {
#   export header_list=("Confirmed" "Deaths" "Recovered" "Active")
    printf "%s \t%s %s \t%s \n" "Confirmed" "Deaths" "Recovered" "Active" | column -t -s $" "
}


corona.get_data () {
    local _location="$1"
    _data="$(cat $source_file | grep """$_location""")"
    _data="${_data//'  '/'_'}"
    _data="${_data//' '/'_'}"
    _data="$(echo $_data | column -t -s ',')"
    export data_list=($_data)
}


corona.print_country_table () {
    [ "$1" ] && location="$1"
    corona.get_data "$1"
    printf "%s \t%s %s \t%s \n" "Confirmed" "Deaths" "Recovered" "Active" | column -t -s $" "
    printf "%s \t\t%s \t%s \t\t%s \n" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}" "${data_list[7]}" | column -t -s $" "
}


corona.print_country_oneline () {
    [ "$1" ] && location="$1"
    corona.get_data "$1"
    printf "${NC}$location ${WHT}%s ${RED}%s ${GRN}%s${NC}\n" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}"
}


corona.print_country_intrest () {

    _country_list=("Finland" "Sweden" "Estonia" "Norway" "Russia" "Germany" "Spain" "France" "Italy" "Kingdom" "China" "US" )

    for _country in ${_country_list[@]}; do
            corona.print_country_oneline "$_country" | column -t -s $":"
        done


}

corona.all () {
    cat "$source_file" | column -t -s $','
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then        # if sourced only import functions
    corona.main $@

fi




# local _header="$(head -n1 $source_file)"
# _header="${_header/" "/"_"}"                                                              # to avoid space slipt of headers
# _header="$(echo $_header | cut -d','  -f4-)"                                              # remove first two columns
# _header="$(echo $_header | column -t -s $',')"                                            # format as table
# export header_list=($_header)
# printf "%s \t%s %s \t%s \n" "${header_list[4]}" "${header_list[5]}" "${header_list[6]}" "${header_list[7]}" | column -t -s $" "