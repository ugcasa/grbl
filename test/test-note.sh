#!/bin/bash
# automatically generated tester for grbl note.sh Mon 03 Mar 2025 03:52:16 AM EET

# sourcing and test variable space
source $GRBL_BIN/common.sh
source ../modules/note.sh

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
    gr.msg -c white "note.$function ${arguments[@]}"

    note.$function ${arguments[@]}

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
        results[$testNr]="p:$returnValue:clean result"
    elif [[ $returnValue -gt 1 ]] && [[ $returnValue -lt 9 ]]; then
        gr.msg -e1 "WARNING"
        results[$testNr]="w:$returnValue:warning"
    elif [[ $returnValue -eq 127 ]] && [[ $returnValue -lt 255 ]]; then
        gr.msg -e2 "NO RESULT"
        results[$testNr]="e:$returnValue:non existing, can be test case issue"
    elif [[ $returnValue -gt 99 ]] && [[ $returnValue -lt 255 ]]; then
        gr.msg -c fail "FAILED"
        results[$testNr]="f:$returnValue:non zero result"
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
                done <note.tc
                ;;
            [1-9]|[1-9][0-9]|[1-9][0-9][0-9])

                runf $(head -$case note.tc | tail +$case)
                ;;
        esac

    done

    print_results
}

print_results () {

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
                gr.msg -w 4 -n -c gray "$(cut -d ':' -f 2 <<<${results[$i]}) "
                gr.msg -w 60 -c dark_grey "$(cut -d ':' -f 3 <<<${results[$i]}) "
                let passes++
                ;;
            f)
                gr.msg -w 10 -n -c fail "FAILED "
                gr.msg -w 4 -n -c grey "$(cut -d ':' -f 2 <<<${results[$i]}) "
                gr.msg -w 60 -c dark_grey "$(cut -d ':' -f 3 <<<${results[$i]}) "
                let fails++
                ;;
            w)
                gr.msg -w 10 -n -e1 "PASSED "
                gr.msg -w 4 -n -c grey "$(cut -d ':' -f 2 <<<${results[$i]}) "
                gr.msg -w 60 -c dark_grey "$(cut -d ':' -f 3 <<<${results[$i]}) "
                let warnings++
                let passes++
                ;;
            e|*)
                gr.msg -w 10 -n -e2 "NO RESULT "
                gr.msg -w 4 -n -c grey "$(cut -d ':' -f 2 <<<${results[$i]}) "
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
note.test() {
    local batch=$1
    shift
    local _results=()
    local _cases=()
    case $batch in
        1)
            runf main non-valid-input -p 2
            runf corsair.systemd_main non-valid-input -p 2
            runf main help -p 0
            runf rc -p 0
            runf make_rc -p 0
            runf check -p 0
            runf main status -p 0 -m Should output module status information
            ;;
        9)
            # these tests install and remove module requirements
            # be sure that installer/uninstallers do not harm hot environment

            gr.ask "run install/remove tests?" || return 0
            runf install -p 0
            runf remove -p 0
            gr.ask "install module requirements to be able to continue tests?" || return 0
            runf install -p 0
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

			echo ; note.test_help || _err=("${_err[@]}" "101") 
			echo ; note.test_main || _err=("${_err[@]}" "102") 
			echo ; note.test_rc || _err=("${_err[@]}" "103") 
			echo ; note.test_make_rc || _err=("${_err[@]}" "104") 
			echo ; note.test_config || _err=("${_err[@]}" "105") 
			echo ; note.test_check || _err=("${_err[@]}" "106") 
			echo ; note.test_locate || _err=("${_err[@]}" "107") 
			echo ; note.test_online || _err=("${_err[@]}" "108") 
			echo ; note.test_remount || _err=("${_err[@]}" "109") 
			echo ; note.test_ls || _err=("${_err[@]}" "110") 
			echo ; note.test_add || _err=("${_err[@]}" "111") 
			echo ; note.test_open_obsidian_vault || _err=("${_err[@]}" "112") 
			echo ; note.test_open || _err=("${_err[@]}" "113") 
			echo ; note.test_rm || _err=("${_err[@]}" "114") 
			echo ; note.test_tag || _err=("${_err[@]}" "115") 
			echo ; note.test_change_log || _err=("${_err[@]}" "116") 
			echo ; note.test_add_change || _err=("${_err[@]}" "117") 
			echo ; note.test_open_editor || _err=("${_err[@]}" "118") 
			echo ; note.test_office || _err=("${_err[@]}" "119") 
			echo ; note.test_html || _err=("${_err[@]}" "120") 
			echo ; note.test_search_tag2 || _err=("${_err[@]}" "121") 
			echo ; note.test_search_tag1 || _err=("${_err[@]}" "122") 
			echo ; note.test_search_tag || _err=("${_err[@]}" "123") 
			echo ; note.test_find || _err=("${_err[@]}" "124") 
			echo ; note.test_status || _err=("${_err[@]}" "125") 
			echo ; note.test_install || _err=("${_err[@]}" "126") 
			echo ; note.test_uninstall || _err=("${_err[@]}" "127") 
            ;;
        # no case and close function
        *) gr.msg "test case  not written"
            return 1
    esac
}

note.test_help () {
# function to test note module function note.help

    local _error=0
    gr.msg -v0 -c white testing note.help

    ## TODO: add pre-conditions here

    note.help ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.help passed
        return 0
    else
        gr.msg -v0 -c red note.help failed
        return 
    fi
}

note.test_main () {
# function to test note module function note.main

    local _error=0
    gr.msg -v0 -c white testing note.main

    ## TODO: add pre-conditions here

    note.main ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.main passed
        return 0
    else
        gr.msg -v0 -c red note.main failed
        return 
    fi
}

note.test_rc () {
# function to test note module function note.rc

    local _error=0
    gr.msg -v0 -c white testing note.rc

    ## TODO: add pre-conditions here

    note.rc ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.rc passed
        return 0
    else
        gr.msg -v0 -c red note.rc failed
        return 
    fi
}

note.test_make_rc () {
# function to test note module function note.make_rc

    local _error=0
    gr.msg -v0 -c white testing note.make_rc

    ## TODO: add pre-conditions here

    note.make_rc ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.make_rc passed
        return 0
    else
        gr.msg -v0 -c red note.make_rc failed
        return 
    fi
}

note.test_config () {
# function to test note module function note.config

    local _error=0
    gr.msg -v0 -c white testing note.config

    ## TODO: add pre-conditions here

    note.config ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.config passed
        return 0
    else
        gr.msg -v0 -c red note.config failed
        return 
    fi
}

note.test_check () {
# function to test note module function note.check

    local _error=0
    gr.msg -v0 -c white testing note.check

    ## TODO: add pre-conditions here

    note.check ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.check passed
        return 0
    else
        gr.msg -v0 -c red note.check failed
        return 
    fi
}

note.test_locate () {
# function to test note module function note.locate

    local _error=0
    gr.msg -v0 -c white testing note.locate

    ## TODO: add pre-conditions here

    note.locate ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.locate passed
        return 0
    else
        gr.msg -v0 -c red note.locate failed
        return 
    fi
}

note.test_online () {
# function to test note module function note.online

    local _error=0
    gr.msg -v0 -c white testing note.online

    ## TODO: add pre-conditions here

    note.online ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.online passed
        return 0
    else
        gr.msg -v0 -c red note.online failed
        return 
    fi
}

note.test_remount () {
# function to test note module function note.remount

    local _error=0
    gr.msg -v0 -c white testing note.remount

    ## TODO: add pre-conditions here

    note.remount ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.remount passed
        return 0
    else
        gr.msg -v0 -c red note.remount failed
        return 
    fi
}

note.test_ls () {
# function to test note module function note.ls

    local _error=0
    gr.msg -v0 -c white testing note.ls

    ## TODO: add pre-conditions here

    note.ls ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.ls passed
        return 0
    else
        gr.msg -v0 -c red note.ls failed
        return 
    fi
}

note.test_add () {
# function to test note module function note.add

    local _error=0
    gr.msg -v0 -c white testing note.add

    ## TODO: add pre-conditions here

    note.add ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.add passed
        return 0
    else
        gr.msg -v0 -c red note.add failed
        return 
    fi
}

note.test_open_obsidian_vault () {
# function to test note module function note.open_obsidian_vault

    local _error=0
    gr.msg -v0 -c white testing note.open_obsidian_vault

    ## TODO: add pre-conditions here

    note.open_obsidian_vault ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.open_obsidian_vault passed
        return 0
    else
        gr.msg -v0 -c red note.open_obsidian_vault failed
        return 
    fi
}

note.test_open () {
# function to test note module function note.open

    local _error=0
    gr.msg -v0 -c white testing note.open

    ## TODO: add pre-conditions here

    note.open ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.open passed
        return 0
    else
        gr.msg -v0 -c red note.open failed
        return 
    fi
}

note.test_rm () {
# function to test note module function note.rm

    local _error=0
    gr.msg -v0 -c white testing note.rm

    ## TODO: add pre-conditions here

    note.rm ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.rm passed
        return 0
    else
        gr.msg -v0 -c red note.rm failed
        return 
    fi
}

note.test_tag () {
# function to test note module function note.tag

    local _error=0
    gr.msg -v0 -c white testing note.tag

    ## TODO: add pre-conditions here

    note.tag ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.tag passed
        return 0
    else
        gr.msg -v0 -c red note.tag failed
        return 
    fi
}

note.test_change_log () {
# function to test note module function note.change_log

    local _error=0
    gr.msg -v0 -c white testing note.change_log

    ## TODO: add pre-conditions here

    note.change_log ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.change_log passed
        return 0
    else
        gr.msg -v0 -c red note.change_log failed
        return 
    fi
}

note.test_add_change () {
# function to test note module function note.add_change

    local _error=0
    gr.msg -v0 -c white testing note.add_change

    ## TODO: add pre-conditions here

    note.add_change ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.add_change passed
        return 0
    else
        gr.msg -v0 -c red note.add_change failed
        return 
    fi
}

note.test_open_editor () {
# function to test note module function note.open_editor

    local _error=0
    gr.msg -v0 -c white testing note.open_editor

    ## TODO: add pre-conditions here

    note.open_editor ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.open_editor passed
        return 0
    else
        gr.msg -v0 -c red note.open_editor failed
        return 
    fi
}

note.test_office () {
# function to test note module function note.office

    local _error=0
    gr.msg -v0 -c white testing note.office

    ## TODO: add pre-conditions here

    note.office ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.office passed
        return 0
    else
        gr.msg -v0 -c red note.office failed
        return 
    fi
}

note.test_html () {
# function to test note module function note.html

    local _error=0
    gr.msg -v0 -c white testing note.html

    ## TODO: add pre-conditions here

    note.html ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.html passed
        return 0
    else
        gr.msg -v0 -c red note.html failed
        return 
    fi
}

note.test_search_tag2 () {
# function to test note module function note.search_tag2

    local _error=0
    gr.msg -v0 -c white testing note.search_tag2

    ## TODO: add pre-conditions here

    note.search_tag2 ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.search_tag2 passed
        return 0
    else
        gr.msg -v0 -c red note.search_tag2 failed
        return 
    fi
}

note.test_search_tag1 () {
# function to test note module function note.search_tag1

    local _error=0
    gr.msg -v0 -c white testing note.search_tag1

    ## TODO: add pre-conditions here

    note.search_tag1 ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.search_tag1 passed
        return 0
    else
        gr.msg -v0 -c red note.search_tag1 failed
        return 
    fi
}

note.test_search_tag () {
# function to test note module function note.search_tag

    local _error=0
    gr.msg -v0 -c white testing note.search_tag

    ## TODO: add pre-conditions here

    note.search_tag ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.search_tag passed
        return 0
    else
        gr.msg -v0 -c red note.search_tag failed
        return 
    fi
}

note.test_find () {
# function to test note module function note.find

    local _error=0
    gr.msg -v0 -c white testing note.find

    ## TODO: add pre-conditions here

    note.find ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.find passed
        return 0
    else
        gr.msg -v0 -c red note.find failed
        return 
    fi
}

note.test_status () {
# function to test note module function note.status

    local _error=0
    gr.msg -v0 -c white testing note.status

    ## TODO: add pre-conditions here

    note.status ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.status passed
        return 0
    else
        gr.msg -v0 -c red note.status failed
        return 
    fi
}

note.test_install () {
# function to test note module function note.install

    local _error=0
    gr.msg -v0 -c white testing note.install

    ## TODO: add pre-conditions here

    note.install ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.install passed
        return 0
    else
        gr.msg -v0 -c red note.install failed
        return 
    fi
}

note.test_uninstall () {
# function to test note module function note.uninstall

    local _error=0
    gr.msg -v0 -c white testing note.uninstall

    ## TODO: add pre-conditions here

    note.uninstall ; _error=$?

    ## TODO: add analysis here and manipulate 

    if  ((_error<1)) ; then
        gr.msg -v0 -c green note.uninstall passed
        return 0
    else
        gr.msg -v0 -c red note.uninstall failed
        return 
    fi
}


if [[ ${BASH_SOURCE[0]} == ${0} ]]; then
    source $GRBL_RC
    GRBL_VERBOSE=2
        note.test $@
fi
