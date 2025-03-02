#!/bin/bash
# automatically generated tester for grbl corsair.sh Sun 02 Mar 2025 08:56:34 PM EET

# sourcing and test variable space
source $GRBL_BIN/common.sh
source ../modules/corsair.sh

# visibility settings
export GRBL_COLOR=true
export GRBL_VERBOSE=2

# add test initial conditions here
gr.msg -v3 -e1 "initial conditions not written"

testNr=1
results=()
results[0]="result:return:note"

runf () {
# result pass/fail handler

    local arguments=()
    local manualMsg=()
    local passCond=0
    local function=

    # getop or getops cannot get string arguments for options, therefore following..
    local m=
    local p=
    for arg in $@; do
        case $arg in
            -m) m=true
                p=
                continue
                ;;
            -p) p=true
                m=
                continue
                ;;
        esac

        if [[ $m ]]; then
            manualMsg+=("$arg")
        elif [[ $p ]]; then
            passCond=$arg
        else
            if [[ $function ]]; then
                arguments+=("$arg")
            else
                function=$arg
            fi
        fi
    done


    gr.msg -N -n -h "Test: $testNr - "
    gr.msg -c white "corsair.$function ${arguments[@]}"

    corsair.$function ${arguments[@]}

    returnValue=$?

    if [[ $manualMsg ]]; then
        if gr.ask "${manualMsg[@]}"; then
            reurnValue=0
        else
            returnValue=255
        fi
    fi

    gr.msg -n -h "Result of test $testNr: "
    if [[ $returnValue -eq $passCond ]]; then
        gr.msg -c pass "PASSED"
        results[$testNr]="p:$returnValue:'$passCond, clean result'"
    elif [[ $returnValue -gt 1 ]] && [[ $returnValue -lt 9 ]]; then
        gr.msg -e1 "WARNING"
        results[$testNr]="w:$returnValue:'warning'"
    elif [[ $returnValue -eq 127 ]] && [[ $returnValue -lt 255 ]]; then
        gr.msg -e2 "NO RESULT"
        results[$testNr]="e:$returnValue:'non existing, can be test case issue'"
    elif [[ $returnValue -gt 99 ]] && [[ $returnValue -lt 255 ]]; then
        gr.msg -c fail "FAILED"
        results[$testNr]="f:$returnValue:'non zero result'"
    else
        gr.msg -e1 "NO RESULT"
        results[$testNr]="e:$returnValue:error in test case"
    fi

    let testNr++
}

runc () {
# run list of cases

    local cases=($@)

    for case in ${cases[@]}; do

        case $case in
            all)
                while read case; do
                    runf "$case"
                done <corsair.tc
                ;;
            [1-9]|[1-9][0-9]|[1-9][0-9][0-9])

                runf $(head -$case corsair.tc | tail +$case)
                ;;
        esac

    done

    local warnings=0
    local passes=0
    local fails=0
    local errors=0
    # echo "${#results[@]}:${results[@]}"
    gr.msg -N -h "Results $(date -d today +${GRBL_FORMAT_DATE}_${GRBL_FORMAT_TIME})"
    for (( i = 1; i < ${#results[@]}; i++ )); do

        gr.msg -n -h -w 4 "$i: "
        case $(cut -d ':' -f 1 <<<${results[$i]}) in
            p)
                gr.msg -w 10 -n -c pass "PASSED "
                gr.msg -w 6 -n -c gray "($(cut -d ':' -f 2 <<<${results[$i]})) "
                gr.msg -w 60 -c dark_grey "$(cut -d ':' -f 3 <<<${results[$i]}) "
                let passes++
                ;;
            f)
                gr.msg -w 10 -n -c fail "FAILED "
                gr.msg -w 6 -n -c grey "($(cut -d ':' -f 2 <<<${results[$i]})) "
                gr.msg -w 60 -c dark_grey "$(cut -d ':' -f 3 <<<${results[$i]}) "
                let fails++
                ;;
            w)
                gr.msg -w 10 -n -e1 "PASSED "
                gr.msg -w 6 -n -c grey "($(cut -d ':' -f 2 <<<${results[$i]})) "
                gr.msg -w 60 -c dark_grey "$(cut -d ':' -f 3 <<<${results[$i]}) "
                let warnings++
                let passes++
                ;;
            e|*)
                gr.msg -w 10 -n -e2 "NO RESULT "
                gr.msg -w 6 -n -c grey "($(cut -d ':' -f 2 <<<${results[$i]})) "
                gr.msg -w 60 -c dark_grey "$(cut -d ':' -f 3 <<<${results[$i]}) "
                let errors++
                ;;
        esac


    done
    gr.msg -h "Summary: $passes passed, $fails fails, $warnings warnings and $errors with no result"
}

case_parcer () {
# parse cases

    local input=($@)
    local cases=()
    local p=0

    for (( i = 0; i < ${#input[@]}; i++ )); do
        case ${input[$i]} in
            *-*)
                local first=$(cut -d '-' -f1 <<<${input[$i]})
                local last=$(cut -d '-' -f2 <<<${input[$i]})
                if ! [[ $last ]] || ! [[ $last ]] || [[ $last -lt $first  ]] ; then
                    gr.msg -e1 "please form-to" >&2
                    return 1
                fi
                gr.debug "adding cases $first to $last: " >&2
                for (( ii = $first; ii <= $last; ii++ )); do
                    cases[$p]=$ii
                    let p++
                done
                ;;
            [1-9]|[1-9][0-9]|[1-9][0-9][0-9])
                cases[$p]=${input[$i]}
                let p++
                ;;
            *)
                gr.msg -e1 "skipping '${input[$i]}'" >&2
        esac
    done
    gr.debug "cases: ${cases[@]}" >&2
    echo ${cases[@]}
    return $?
}


# function and tests 1-9
corsair.test() {
    local batch=$1
    shift
    local _results=()
    local _cases=()
    case $batch in
        1)
            # manual validation
            runf main status -m "should output module status oneliner"

            ## pass conditions

            # return value is (default is 0)
            runf main status -p <9

            # should return string no more than one \n
            runf main status -p string

            # should return one or more lines
            runf main status -p lines

            # should return "ok" string
            runf main status -p "ok"

            ## do we really need fail conditions?

            runf main nonvalidinput
            runf help ; result $?
            runf rc
            runf makerc -f \tmp$USER$module.rc
            runf status
            runf help
            ;;
        9)
            # these tests install and remove module requirements
            # be sure that installer/uninstallers do not harm hot environment
            gr.ask "run install/remove tests?" || return 0
            corsair.install &&  _results+=(f:91) || _results+=(f:91)
            corsair.remove || _results+=(f:92)
            gr.ask "install module requirements to be able to continue tests?" || return 0
            corsair.install || _results+=(f:93)
            ;;

        case|c)
            # run _cases. input '1 2 3' or '4-8' = .tc file line number
            _cases=($(case_parcer $@))
            runc ${_cases[@]}
            ;;

        cases|tc)
            # run all cases
            runc all
            ;;

        all)
        # all tests = all functions in introduction order
        # TODO: remove non wanted functions and check run order.
			echo ; corsair.test_help-profile || _err=("${_err[@]}" "101") 
			echo ; corsair.test_help || _err=("${_err[@]}" "102") 
			echo ; corsair.test_keytable || _err=("${_err[@]}" "103") 
			echo ; corsair.test_main || _err=("${_err[@]}" "104") 
			echo ; corsair.test_systemd_main || _err=("${_err[@]}" "105") 
			echo ; corsair.test_blink_all || _err=("${_err[@]}" "106") 
			echo ; corsair.test_get_key_id || _err=("${_err[@]}" "107") 
			echo ; corsair.test_get_pipefile || _err=("${_err[@]}" "108") 
			echo ; corsair.test_key-id || _err=("${_err[@]}" "109") 
			echo ; corsair.test_enabled || _err=("${_err[@]}" "110") 
			echo ; corsair.test_check || _err=("${_err[@]}" "111") 
			echo ; corsair.test_init || _err=("${_err[@]}" "112") 
			echo ; corsair.test_set || _err=("${_err[@]}" "113") 
			echo ; corsair.test_reset || _err=("${_err[@]}" "114") 
			echo ; corsair.test_clear || _err=("${_err[@]}" "115") 
			echo ; corsair.test_end || _err=("${_err[@]}" "116") 
			echo ; corsair.test_check_pipe || _err=("${_err[@]}" "117") 
			echo ; corsair.test_indicate || _err=("${_err[@]}" "118") 
			echo ; corsair.test_blink_set || _err=("${_err[@]}" "119") 
			echo ; corsair.test_blink_stop || _err=("${_err[@]}" "120") 
			echo ; corsair.test_blink_kill || _err=("${_err[@]}" "121") 
			echo ; corsair.test_blink_test || _err=("${_err[@]}" "122") 
			echo ; corsair.test_type_end || _err=("${_err[@]}" "123") 
			echo ; corsair.test_type || _err=("${_err[@]}" "124") 
			echo ; corsair.test_systemd_status || _err=("${_err[@]}" "125") 
			echo ; corsair.test_systemd_fix || _err=("${_err[@]}" "126") 
			echo ; corsair.test_systemd_start || _err=("${_err[@]}" "127") 
			echo ; corsair.test_systemd_stop || _err=("${_err[@]}" "128") 
			echo ; corsair.test_systemd_restart || _err=("${_err[@]}" "129") 
			echo ; corsair.test_systemd_restart_daemon || _err=("${_err[@]}" "130") 
			echo ; corsair.test_systemd_start_daemon || _err=("${_err[@]}" "131") 
			echo ; corsair.test_systemd_stop_daemon || _err=("${_err[@]}" "132") 
			echo ; corsair.test_systemd_restart_app || _err=("${_err[@]}" "133") 
			echo ; corsair.test_systemd_start_app || _err=("${_err[@]}" "134") 
			echo ; corsair.test_systemd_stop_app || _err=("${_err[@]}" "135") 
			echo ; corsair.test_systemd_make_daemon_service || _err=("${_err[@]}" "136") 
			echo ; corsair.test_systemd_make_app_service || _err=("${_err[@]}" "137") 
			echo ; corsair.test_systemd_setup || _err=("${_err[@]}" "138") 
			echo ; corsair.test_systemd_disable || _err=("${_err[@]}" "139") 
			echo ; corsair.test_suspend_recovery || _err=("${_err[@]}" "140") 
			echo ; corsair.test_clone || _err=("${_err[@]}" "141") 
			echo ; corsair.test_patch || _err=("${_err[@]}" "142") 
			echo ; corsair.test_compile || _err=("${_err[@]}" "143") 
			echo ; corsair.test_requirements || _err=("${_err[@]}" "144") 
			echo ; corsair.test_poll || _err=("${_err[@]}" "145") 
			echo ; corsair.test_status || _err=("${_err[@]}" "146") 
			echo ; corsair.test_install || _err=("${_err[@]}" "147") 
			echo ; corsair.test_remove || _err=("${_err[@]}" "148") 
			echo ; corsair.test_rc || _err=("${_err[@]}" "149") 
			echo ; corsair.test_make_rc || _err=("${_err[@]}" "150") 
            ;;
        # no case and close function
        *) gr.msg "test case  not written"
            return 1
    esac
}
corsair.test_help-profile () {
# function to test corsair module function corsair.help-profile

    local _error=0
    gr.msg -v0 -c white testing corsair.help-profile

    ## TODO: add pre-conditions here

    corsair.help-profile ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.help-profile passed
        return 0
    else
        gr.msg -v0 -c red corsair.help-profile failed
        return 
    fi
}

corsair.test_help () {
# function to test corsair module function corsair.help

    local _error=0
    gr.msg -v0 -c white testing corsair.help

    ## TODO: add pre-conditions here

    corsair.help ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.help passed
        return 0
    else
        gr.msg -v0 -c red corsair.help failed
        return 
    fi
}

corsair.test_keytable () {
# function to test corsair module function corsair.keytable

    local _error=0
    gr.msg -v0 -c white testing corsair.keytable

    ## TODO: add pre-conditions here

    corsair.keytable ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.keytable passed
        return 0
    else
        gr.msg -v0 -c red corsair.keytable failed
        return 
    fi
}

corsair.test_main () {
# function to test corsair module function corsair.main

    local _error=0
    gr.msg -v0 -c white testing corsair.main

    ## TODO: add pre-conditions here

    corsair.main ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.main passed
        return 0
    else
        gr.msg -v0 -c red corsair.main failed
        return 
    fi
}

corsair.test_systemd_main () {
# function to test corsair module function corsair.systemd_main

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_main

    ## TODO: add pre-conditions here

    corsair.systemd_main ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_main passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_main failed
        return 
    fi
}

corsair.test_blink_all () {
# function to test corsair module function corsair.blink_all

    local _error=0
    gr.msg -v0 -c white testing corsair.blink_all

    ## TODO: add pre-conditions here

    corsair.blink_all ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.blink_all passed
        return 0
    else
        gr.msg -v0 -c red corsair.blink_all failed
        return 
    fi
}

corsair.test_get_key_id () {
# function to test corsair module function corsair.get_key_id

    local _error=0
    gr.msg -v0 -c white testing corsair.get_key_id

    ## TODO: add pre-conditions here

    corsair.get_key_id ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.get_key_id passed
        return 0
    else
        gr.msg -v0 -c red corsair.get_key_id failed
        return 
    fi
}

corsair.test_get_pipefile () {
# function to test corsair module function corsair.get_pipefile

    local _error=0
    gr.msg -v0 -c white testing corsair.get_pipefile

    ## TODO: add pre-conditions here

    corsair.get_pipefile ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.get_pipefile passed
        return 0
    else
        gr.msg -v0 -c red corsair.get_pipefile failed
        return 
    fi
}

corsair.test_key-id () {
# function to test corsair module function corsair.key-id

    local _error=0
    gr.msg -v0 -c white testing corsair.key-id

    ## TODO: add pre-conditions here

    corsair.key-id ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.key-id passed
        return 0
    else
        gr.msg -v0 -c red corsair.key-id failed
        return 
    fi
}

corsair.test_enabled () {
# function to test corsair module function corsair.enabled

    local _error=0
    gr.msg -v0 -c white testing corsair.enabled

    ## TODO: add pre-conditions here

    corsair.enabled ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.enabled passed
        return 0
    else
        gr.msg -v0 -c red corsair.enabled failed
        return 
    fi
}

corsair.test_check () {
# function to test corsair module function corsair.check

    local _error=0
    gr.msg -v0 -c white testing corsair.check

    ## TODO: add pre-conditions here

    corsair.check ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.check passed
        return 0
    else
        gr.msg -v0 -c red corsair.check failed
        return 
    fi
}

corsair.test_init () {
# function to test corsair module function corsair.init

    local _error=0
    gr.msg -v0 -c white testing corsair.init

    ## TODO: add pre-conditions here

    corsair.init ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.init passed
        return 0
    else
        gr.msg -v0 -c red corsair.init failed
        return 
    fi
}

corsair.test_set () {
# function to test corsair module function corsair.set

    local _error=0
    gr.msg -v0 -c white testing corsair.set

    ## TODO: add pre-conditions here

    corsair.set ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.set passed
        return 0
    else
        gr.msg -v0 -c red corsair.set failed
        return 
    fi
}

corsair.test_reset () {
# function to test corsair module function corsair.reset

    local _error=0
    gr.msg -v0 -c white testing corsair.reset

    ## TODO: add pre-conditions here

    corsair.reset ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.reset passed
        return 0
    else
        gr.msg -v0 -c red corsair.reset failed
        return 
    fi
}

corsair.test_clear () {
# function to test corsair module function corsair.clear

    local _error=0
    gr.msg -v0 -c white testing corsair.clear

    ## TODO: add pre-conditions here

    corsair.clear ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.clear passed
        return 0
    else
        gr.msg -v0 -c red corsair.clear failed
        return 
    fi
}

corsair.test_end () {
# function to test corsair module function corsair.end

    local _error=0
    gr.msg -v0 -c white testing corsair.end

    ## TODO: add pre-conditions here

    corsair.end ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.end passed
        return 0
    else
        gr.msg -v0 -c red corsair.end failed
        return 
    fi
}

corsair.test_check_pipe () {
# function to test corsair module function corsair.check_pipe

    local _error=0
    gr.msg -v0 -c white testing corsair.check_pipe

    ## TODO: add pre-conditions here

    corsair.check_pipe ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.check_pipe passed
        return 0
    else
        gr.msg -v0 -c red corsair.check_pipe failed
        return 
    fi
}

corsair.test_indicate () {
# function to test corsair module function corsair.indicate

    local _error=0
    gr.msg -v0 -c white testing corsair.indicate

    ## TODO: add pre-conditions here

    corsair.indicate ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.indicate passed
        return 0
    else
        gr.msg -v0 -c red corsair.indicate failed
        return 
    fi
}

corsair.test_blink_set () {
# function to test corsair module function corsair.blink_set

    local _error=0
    gr.msg -v0 -c white testing corsair.blink_set

    ## TODO: add pre-conditions here

    corsair.blink_set ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.blink_set passed
        return 0
    else
        gr.msg -v0 -c red corsair.blink_set failed
        return 
    fi
}

corsair.test_blink_stop () {
# function to test corsair module function corsair.blink_stop

    local _error=0
    gr.msg -v0 -c white testing corsair.blink_stop

    ## TODO: add pre-conditions here

    corsair.blink_stop ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.blink_stop passed
        return 0
    else
        gr.msg -v0 -c red corsair.blink_stop failed
        return 
    fi
}

corsair.test_blink_kill () {
# function to test corsair module function corsair.blink_kill

    local _error=0
    gr.msg -v0 -c white testing corsair.blink_kill

    ## TODO: add pre-conditions here

    corsair.blink_kill ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.blink_kill passed
        return 0
    else
        gr.msg -v0 -c red corsair.blink_kill failed
        return 
    fi
}

corsair.test_blink_test () {
# function to test corsair module function corsair.blink_test

    local _error=0
    gr.msg -v0 -c white testing corsair.blink_test

    ## TODO: add pre-conditions here

    corsair.blink_test ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.blink_test passed
        return 0
    else
        gr.msg -v0 -c red corsair.blink_test failed
        return 
    fi
}

corsair.test_type_end () {
# function to test corsair module function corsair.type_end

    local _error=0
    gr.msg -v0 -c white testing corsair.type_end

    ## TODO: add pre-conditions here

    corsair.type_end ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.type_end passed
        return 0
    else
        gr.msg -v0 -c red corsair.type_end failed
        return 
    fi
}

corsair.test_type () {
# function to test corsair module function corsair.type

    local _error=0
    gr.msg -v0 -c white testing corsair.type

    ## TODO: add pre-conditions here

    corsair.type ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.type passed
        return 0
    else
        gr.msg -v0 -c red corsair.type failed
        return 
    fi
}

corsair.test_systemd_status () {
# function to test corsair module function corsair.systemd_status

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_status

    ## TODO: add pre-conditions here

    corsair.systemd_status ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_status passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_status failed
        return 
    fi
}

corsair.test_systemd_fix () {
# function to test corsair module function corsair.systemd_fix

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_fix

    ## TODO: add pre-conditions here

    corsair.systemd_fix ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_fix passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_fix failed
        return 
    fi
}

corsair.test_systemd_start () {
# function to test corsair module function corsair.systemd_start

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_start

    ## TODO: add pre-conditions here

    corsair.systemd_start ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_start passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_start failed
        return 
    fi
}

corsair.test_systemd_stop () {
# function to test corsair module function corsair.systemd_stop

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_stop

    ## TODO: add pre-conditions here

    corsair.systemd_stop ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_stop passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_stop failed
        return 
    fi
}

corsair.test_systemd_restart () {
# function to test corsair module function corsair.systemd_restart

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_restart

    ## TODO: add pre-conditions here

    corsair.systemd_restart ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_restart passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_restart failed
        return 
    fi
}

corsair.test_systemd_restart_daemon () {
# function to test corsair module function corsair.systemd_restart_daemon

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_restart_daemon

    ## TODO: add pre-conditions here

    corsair.systemd_restart_daemon ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_restart_daemon passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_restart_daemon failed
        return 
    fi
}

corsair.test_systemd_start_daemon () {
# function to test corsair module function corsair.systemd_start_daemon

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_start_daemon

    ## TODO: add pre-conditions here

    corsair.systemd_start_daemon ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_start_daemon passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_start_daemon failed
        return 
    fi
}

corsair.test_systemd_stop_daemon () {
# function to test corsair module function corsair.systemd_stop_daemon

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_stop_daemon

    ## TODO: add pre-conditions here

    corsair.systemd_stop_daemon ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_stop_daemon passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_stop_daemon failed
        return 
    fi
}

corsair.test_systemd_restart_app () {
# function to test corsair module function corsair.systemd_restart_app

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_restart_app

    ## TODO: add pre-conditions here

    corsair.systemd_restart_app ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_restart_app passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_restart_app failed
        return 
    fi
}

corsair.test_systemd_start_app () {
# function to test corsair module function corsair.systemd_start_app

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_start_app

    ## TODO: add pre-conditions here

    corsair.systemd_start_app ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_start_app passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_start_app failed
        return 
    fi
}

corsair.test_systemd_stop_app () {
# function to test corsair module function corsair.systemd_stop_app

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_stop_app

    ## TODO: add pre-conditions here

    corsair.systemd_stop_app ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_stop_app passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_stop_app failed
        return 
    fi
}

corsair.test_systemd_make_daemon_service () {
# function to test corsair module function corsair.systemd_make_daemon_service

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_make_daemon_service

    ## TODO: add pre-conditions here

    corsair.systemd_make_daemon_service ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_make_daemon_service passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_make_daemon_service failed
        return 
    fi
}

corsair.test_systemd_make_app_service () {
# function to test corsair module function corsair.systemd_make_app_service

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_make_app_service

    ## TODO: add pre-conditions here

    corsair.systemd_make_app_service ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_make_app_service passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_make_app_service failed
        return 
    fi
}

corsair.test_systemd_setup () {
# function to test corsair module function corsair.systemd_setup

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_setup

    ## TODO: add pre-conditions here

    corsair.systemd_setup ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_setup passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_setup failed
        return 
    fi
}

corsair.test_systemd_disable () {
# function to test corsair module function corsair.systemd_disable

    local _error=0
    gr.msg -v0 -c white testing corsair.systemd_disable

    ## TODO: add pre-conditions here

    corsair.systemd_disable ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.systemd_disable passed
        return 0
    else
        gr.msg -v0 -c red corsair.systemd_disable failed
        return 
    fi
}

corsair.test_suspend_recovery () {
# function to test corsair module function corsair.suspend_recovery

    local _error=0
    gr.msg -v0 -c white testing corsair.suspend_recovery

    ## TODO: add pre-conditions here

    corsair.suspend_recovery ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.suspend_recovery passed
        return 0
    else
        gr.msg -v0 -c red corsair.suspend_recovery failed
        return 
    fi
}

corsair.test_clone () {
# function to test corsair module function corsair.clone

    local _error=0
    gr.msg -v0 -c white testing corsair.clone

    ## TODO: add pre-conditions here

    corsair.clone ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.clone passed
        return 0
    else
        gr.msg -v0 -c red corsair.clone failed
        return 
    fi
}

corsair.test_patch () {
# function to test corsair module function corsair.patch

    local _error=0
    gr.msg -v0 -c white testing corsair.patch

    ## TODO: add pre-conditions here

    corsair.patch ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.patch passed
        return 0
    else
        gr.msg -v0 -c red corsair.patch failed
        return 
    fi
}

corsair.test_compile () {
# function to test corsair module function corsair.compile

    local _error=0
    gr.msg -v0 -c white testing corsair.compile

    ## TODO: add pre-conditions here

    corsair.compile ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.compile passed
        return 0
    else
        gr.msg -v0 -c red corsair.compile failed
        return 
    fi
}

corsair.test_requirements () {
# function to test corsair module function corsair.requirements

    local _error=0
    gr.msg -v0 -c white testing corsair.requirements

    ## TODO: add pre-conditions here

    corsair.requirements ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.requirements passed
        return 0
    else
        gr.msg -v0 -c red corsair.requirements failed
        return 
    fi
}

corsair.test_poll () {
# function to test corsair module function corsair.poll

    local _error=0
    gr.msg -v0 -c white testing corsair.poll

    ## TODO: add pre-conditions here

    corsair.poll ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.poll passed
        return 0
    else
        gr.msg -v0 -c red corsair.poll failed
        return 
    fi
}

corsair.test_status () {
# function to test corsair module function corsair.status

    local _error=0
    gr.msg -v0 -c white testing corsair.status

    ## TODO: add pre-conditions here

    corsair.status ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.status passed
        return 0
    else
        gr.msg -v0 -c red corsair.status failed
        return 
    fi
}

corsair.test_install () {
# function to test corsair module function corsair.install

    local _error=0
    gr.msg -v0 -c white testing corsair.install

    ## TODO: add pre-conditions here

    corsair.install ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.install passed
        return 0
    else
        gr.msg -v0 -c red corsair.install failed
        return 
    fi
}

corsair.test_remove () {
# function to test corsair module function corsair.remove

    local _error=0
    gr.msg -v0 -c white testing corsair.remove

    ## TODO: add pre-conditions here

    corsair.remove ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.remove passed
        return 0
    else
        gr.msg -v0 -c red corsair.remove failed
        return 
    fi
}

corsair.test_rc () {
# function to test corsair module function corsair.rc

    local _error=0
    gr.msg -v0 -c white testing corsair.rc

    ## TODO: add pre-conditions here

    corsair.rc ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.rc passed
        return 0
    else
        gr.msg -v0 -c red corsair.rc failed
        return 
    fi
}

corsair.test_make_rc () {
# function to test corsair module function corsair.make_rc

    local _error=0
    gr.msg -v0 -c white testing corsair.make_rc

    ## TODO: add pre-conditions here

    corsair.make_rc ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green corsair.make_rc passed
        return 0
    else
        gr.msg -v0 -c red corsair.make_rc failed
        return 
    fi
}


if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    source $GRBL_RC
    GRBL_VERBOSE=2
        corsair.test $@
fi
