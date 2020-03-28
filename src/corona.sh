

source $GURU_BIN/lib/common.sh
source $GURU_BIN/lib/deco.sh


corona.get_data()
{
	local _clone_location="$HOME/git/try"
	if ! [ -d "$HOME/git/try" ]; then
			mkdir -p "$HOME/git/try"
		fi
	cd "$_clone_location"

	local _location="Finland" ; [ "$1" ] && _location="$1"
	local _column=5 ; [ "$2" ] && _column="$2"				# Deaths
	local _source_date="yesterday"
	local _source_file="$(date -d $_source_date +%m-%d-%Y).csv"
	local _report_location="COVID-19/csse_covid_19_data/csse_covid_19_daily_reports/"

	if ! [ -f "$_report_location/$_source_file" ]; then
			rm -rf COVID-19
			git clone git@github.com:CSSEGISandData/COVID-19.git
		fi

	cd "$_report_location"

	local _header="$(head -n1 $_source_file)"
	_header="${_header/" "/"_"}" 																# to avoid space slipt of headers
	_header="$(echo $_header | cut -d','  -f4-)"												# remove first two columns
	_header="$(echo $_header | column -t -s $',')" 											# format as table
	export _header_list=($_header)

	_data="$(cat $_source_file |grep $_location)"
	_data="${_data/" "/"_"}"
	_data="$(echo $_data | column -t -s $',')"
	export _data_list=($_data)

}

corona.print () {
	printf "%s \t%s %s \t%s \n" "${_header_list[4]}" "${_header_list[5]}" "${_header_list[6]}" "${_header_list[7]}" | column -t -s $" "
	printf "%s \t\t%s \t%s \t\t%s \n" "${_data_list[4]}" "${_data_list[5]}" "${_data_list[6]}" "${_data_list[7]}" | column -t -s $" "
}


corona.country () {
	corona.get_data "$@"
	corona.print
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then        # if sourced only import functions
    corona.country "$@"
fi


