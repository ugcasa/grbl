#!/bin/bash
# query results before 30.11.2022 is test date
# source common.sh

declare -gA fingrid

source $GURU_CFG/fingrid.cfg
[[ -f $GURU_CFG/$GURU_USER/fingrid.cfg ]] && source $GURU_CFG/$GURU_USER/fingrid.cfg

if [[ $(stat -c %Y $GURU_CFG/$GURU_USER/fingrid.cfg) -gt $(stat -c %Y /tmp/guru.daemon-pid) ]] ; then
            gr.msg -v1 -c dark_gray "$GURU_CFG/$GURU_USER/fingrid.cfg updated"
        fi


fingrid.main () {
# fingrid main command parser
    local _cmd="$1" ; shift
    case "$_cmd" in
               status|poll|info|get_value)
                    fingrid.$_cmd "$@"
                    return $?
                    ;;
               *)   gr.msg -c yellow "${FUNCNAME[0]}: unknown command: $_cmd"
                    return 2
        esac
    return 0
}


fingrid.check () {
# check that user is registered
    if ! [[ ${fingrid[api_key]} ]] ; then
            gr.msg -c yellow "please set global variable fingrid[api_key]"
            gr.msg -v1 "get access to Fingrids open datasets at https://data.fingrid.fi/open-data-forms/registration"
            return 100
        fi
}


fingrid.get_value () {
# get last hours value(s) of finnish electric grid status and printout last one (TBD and trend)
    local variable_id='209'

    case variable_id in
            262) interwal="two days ago";;
            93|92|96|262|319) interwal="two hours ago";;
            209|181|192|183|201|188|191|206|185|182|178|198|192|177) interwal="5 minutes ago";;
              *) interwal="123 minutes ago";;
          esac

    [[ $1 ]] && variable_id="$1"
    # local start_time=$(date --date="3 minutes ago" +"%Y-%m-%dT%H:%M:%S%:z" | sed -e 's/:/%3A/g' | sed -e 's/+/%2B/g')
    local start_time=$(date --date="$interwal" +"%Y-%m-%dT%H:%M:%S%:z" | sed -e 's/:/%3A/g' | sed -e 's/+/%2B/g')
    local end_time=$(date +"%Y-%m-%dT%H:%M:%S%:z" | sed -e 's/:/%3A/g' | sed -e 's/+/%2B/g')
    local answer_json=$(curl -s -X GET \
        "https://api.fingrid.fi/v1/variable/$variable_id/events/json?start_time=$start_time&end_time=$end_time" \
        --header 'Accept: application/json' \
        --header "x-api-key: ${fingrid[api_key]}" \
        )
    # [[ GURU_VERBOSE -gt 3 ]] && echo $answer_json | jq
    local value=$(echo $answer_json | jq | grep value | tail | xargs | cut -d ' ' -f2 | sed -e 's/,//g')
    echo $value
}


fingrid.status () {
# printout network status
    fingrid.check || return $?
    source $GURU_BIN/audio/audio.sh

    gr.msg -t -v1 -n "${FUNCNAME[0]}: "

    if [[ ${fingrid[enabled]} ]] ; then
            gr.msg -v2 -n -c green "enabled, " -k ${fingrid[indicator_key]}
        else
            gr.msg -v1 -c black "disabled" -k ${fingrid[indicator_key]}
            return 100
        fi

    local grid_status=$(fingrid.get_value 209)

    case $grid_status in
            *1) gr.end ${fingrid[indicator_key]}
                gr.msg -v1 -n -c green "normal " -k ${fingrid[indicator_key]}
                gr.msg -v1 "The operating status of the electrical system is normal."
                ;;
            *2) audio.main pause
                gr.msg -n -c yellow "under threat "
                gr.msg -v1 -s -c white "The operating situation of the electrical system has deteriorated. The sufficiency of electricity in Finland is under threat (the risk of power shortages is high) or the power system does not meet the security criteria"
                gr.ind warning -m "electric grid is in under threat" -k ${fingrid[indicator_key]}
                audio.main pause
                ;;
            *3) audio.main radio yle yksi
                gr.msg -n -c orange "in danger! "
                gr.msg -v1 -s -h "The operational reliability of the electrical system is at risk. Electricity consumption has been disconnected to ensure the operational reliability of the power system (power shortage) or the risk of a large-scale power outage is considerable."
                gr.ind alert -m "electric grid is in danger!" -k ${fingrid[indicator_key]}
                ;;
            *4) audio.main radio yle yksi
                gr.msg -n -c red "nationwide disruptions! "
                gr.msg -v1 -s -h "A serious disturbance covering a large part of country or the whole of Finland."
                gr.ind panic -m "electric grid is about to collapse!" -k ${fingrid[indicator_key]}
                ;;
            *5) gr.msg -n -c sky_blue "in recovery "
                gr.msg -v1 -s -c white "The restoration of the use of a serious glitch is going. For more information https://www.fingrid.fi/sahkomarkkinat/sahkojarjestelman-tila/"
                gr.ind recovery -m "electrical grid" -k ${fingrid[indicator_key]}
                ;;
            *)  gr.msg -c yellow "something went wrong.."
                return 112
        esac

    local consumption=$(fingrid.get_value 193)
    local production=$(fingrid.get_value 74)
    local freq=$(fingrid.get_value 177)

    gr.msg -v2 "consumption $consumption MW, production $production MWh/h (freq $freq Hz)"

    return 0
}


fingrid.info () {

    local grid_status=$(fingrid.get_value 209)
    gr.msg
    gr.msg -v1 -n "Finnish electric grid status is: "

    case $grid_status in
            *1) gr.msg -v1 -c green "normal " -k ${fingrid[indicator_key]}
                gr.msg "The operating status of the electrical system is normal."
                ;;
            *2) gr.msg -c yellow "under threat "
                gr.msg "The operating situation of the electrical system has deteriorated. The sufficiency of electricity in Finland is under threat (the risk of power shortages is high) or the power system does not meet the security criteria"
                ;;
            *3) gr.msg -c orange "in danger! "
                gr.msg "The operational reliability of the electrical system is at risk. Electricity consumption has been disconnected to ensure the operational reliability of the power system (power shortage) or the risk of a large-scale power outage is considerable."
                ;;
            *4) gr.msg -c red "nationwide disruptions! "
                gr.msg "A serious disturbance covering a large part of country or the whole of Finland."
                ;;
            *5) gr.msg -c sky_blue "in recovery "
                gr.msg "The restoration of the use of a serious glitch is going. For more information https://www.fingrid.fi/sahkomarkkinat/sahkojarjestelman-tila/"
                ;;
        esac

    gr.msg
    gr.msg " total production: $(fingrid.get_value 74) MWh/h " -c white
    gr.msg "          nuclear: $(fingrid.get_value 188) MW" -v1
    gr.msg "industrial common: $(fingrid.get_value 201) MW" -v1
    gr.msg "            hydro: $(fingrid.get_value 191) MW" -v1
    # gr.msg "             wind: $(fingrid.get_value 75) MWh/h"
    gr.msg "             wind: $(fingrid.get_value 181) MW" -v1
    gr.msg "  wind prediction: $(fingrid.get_value 245) MWh/h" -v2
    # gr.msg "            solar: $(fingrid.get_value ) MW"
    gr.msg " solar prediction: $(fingrid.get_value 267) MW" -v2
    gr.msg
    gr.msg "production over/underhead: $(fingrid.get_value 198) MW" -v2
    gr.msg "      inport(-)/export(+): $(fingrid.get_value 194) MW" -v1
    gr.msg
    gr.msg " total consumption: $(fingrid.get_value 193) MW" -c white
    gr.msg "      24h forecast: $(fingrid.get_value 165) MW" -v1
    gr.msg "          forecast: $(fingrid.get_value 166) MWh/h" -v2
    gr.msg "     power reserve: $(fingrid.get_value 183) MW" -v2
    gr.msg " temperature north: $(fingrid.get_value 185) C" -v1
    gr.msg " temperature south: $(fingrid.get_value 178) C" -v2
    gr.msg "   temperature mid: $(fingrid.get_value 182) C" -v2
    gr.msg
    gr.msg "   network frequensy: $(fingrid.get_value 177) Hz" -v1
    gr.msg "frequensy difference: $(fingrid.get_value 206) Hz" -v2
    gr.msg
    gr.msg "          sell price: $(fingrid.get_value 93) €/MWh" -v3
    gr.msg "    production price: $(fingrid.get_value 92) €/MWh" -v3
    gr.msg "           buy price: $(fingrid.get_value 96) €/MWh" -v3
    gr.msg "      marginal price: $(fingrid.get_value 262) €/MWh" -v3
    gr.msg " tasepoikkeama price: $(fingrid.get_value 319) €/MWh" -v3
    gr.msg "    carbon emissions: $(fingrid.get_value 265) gCO2/kWh"
    gr.msg
    return 0
}


fingrid.install () {

    sudo apt install jq curl
}


fingrid.poll () {
    # poll functions

    local _cmd="$1" ; shift

    case $_cmd in
            start )
                gr.msg -v1 -t -c black "${FUNCNAME[0]}: fingrid status polling started" -k ${fingrid[indicator_key]}
                ;;
            end )
                gr.msg -v1 -t -c reset "${FUNCNAME[0]}: fingrid status polling ended" -k ${fingrid[indicator_key]}
                ;;
            status )
                fingrid.status
                ;;
            *)  gr.msg -c dark_grey "function not written"
                return 0
        esac
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fingrid.main "$@"
    exit "$?"
fi




# variableId
#  https://api.fingrid.fi/v1/variable/variableId/events/xml


# - [documentation](https://data.fingrid.fi/fi/pages/api)
# - [svägä](https://data.fingrid.fi/open-data-api/)

# https://data.fingrid.fi/open-data-forms/registration/

# UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am > fingrid[api_key]


# ## case: liikennevalot
# start_time

# GET https://api.fingrid.fi/v1/variable/209/events/json=?
# x-api-key: UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am
# Content-Type: application/json
# start_time: $(date +"%Y-%m-%dT%H:%M:%S%:z")
# end_time: $(date +"%Y-%m-%dT%H:%M:%S%:z")

# Authorization: Bearier UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am


# wget --method=get -O- --body-data='{"x-api-key": "UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am", }' --header=Content-Type:application/json https://api.fingrid.fi/v1/variable/209/events/json=?



# wget --method=get -O- --header='{"Authorization": "Bearier UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am", "Content-Type": "application/json"}' https://api.fingrid.fi/v1/variable/209/events/json=?


# wget --method=get -O- --header={"Authorization": "Bearier UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am", "Content-Type": "application/json", "start_time": "$(date +%Y-%m-%dT%H:%M:%S%:z)", "end_time": "$(date +%Y-%m-%dT%H:%M:%S%:z)"} https://api.fingrid.fi/v1/variable/209/events/json=?



# wget --method=get -O- --header="x-api-key: UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am" --header="Content-Type: application/json" --header="start_time: 2022-12-03T00:10:56+02:00" --header="end_time: 2022-12-03T00:10:57+02:00" https://api.fingrid.fi/v1/variable/209/events/json=?


# wget --method=get  -O- -q https://jsonplaceholder.typicode.com/posts?_limit=2


# #ei saa mitään wgetillä aikaseksi, curlaillaas

# Verkon tila :
#     curl -X GET --header 'Accept: application/json' --header 'x-api-key: UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am' 'https://api.fingrid.fi/v1/variable/209/events/json?start_time=2022-12-03T00%3A9%3A56%2B02%3A00&end_time=2022-12-03T00%3A10%3A56%2B02%3A00'



# Tehoreservi
#     curl -X GET --header 'Accept: application/json' --header 'x-api-key: UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am' 'https://api.fingrid.fi/v1/variable/183/events/json?start_time=2022-12-03T00%3A9%3A56%2B02%3A00&end_time=2022-12-03T00%3A10%3A56%2B02%3A00'

# Venäjän tuonti
#     curl -X GET --header 'Accept: application/json' --header 'x-api-key: UjA4an4qWo6eaMAc7kb6E7EgWUNXqudQ3hHSF8am' 'https://api.fingrid.fi/v1/variable/195/events/json?start_time=2022-12-03T00%3A9%3A56%2B02%3A00&end_time=2022-12-03T00%3A10%3A56%2B02%3A00'



# toimii mutta timestamp ihan paskaa..
# joo, goisaamaan


# # timestamp

# 2022-12-03T00%3A10%3A56%2B02%3A00
# 2022-12-03T00 %3A 10 %3A 56 %2B 02 %3A 00
# 2022-12-02T23 : 42 : 16 + 02 : 00



# #response format

# ```json
# [
#   {
#     "end_time": "string",
#     "start_time": "string",
#     "value": 0,
#     "variable_id": 0
#   }
# ]
# ```

# #errors

# 404     Invalid variable id
# 416     Requested row count is too large
# 503     The variable is currently on maintenance break