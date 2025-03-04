#!/bin/bash
# grbl build tester for module
# creates template based tester script for existing module
# input: <module_name>
# output: test-<module_name>.sh

source $GRBL_RC
source common.sh
GRBL_COLOR=true
GRBL_VERBOSE=2

[[ "$1" ]] && module=$1 || read -p "module name to create test for (no file ending): " module

# module location
if [[ -f "../core/$module.sh" ]] ; then
        module_to_test="../core/$module.sh"
    elif [[ -f "../modules/$module.sh" ]] ; then
        module_to_test="../modules/$module.sh"
    elif [[ -f "$GRBL_BIN/$module.sh" ]] ; then
        module_to_test="$GRBL_BIN/$module.sh"
    else
        gr.msg -c yellow "no module '$module' found in any location"
        exit 12
    fi

gr.msg -c white "generating tester for $module_to_test"
# only if space is left between function name and "()" TEST space removed!
functions_to_test=($(cat $module_to_test | grep " ()"  | grep -v "#" |cut -f1 -d " "))
# TODO TEST better: functions_to_test=($(grep $module_to_test -e " ()"  | grep -v "#" | cut -f1 -d " "))
tester_file_name="test-""$module"".sh"

gr.msg -v3 -c blue "module: $module_to_test"
gr.msg -v3 -c blue "output: $tester_file_name"
gr.msg "${#functions_to_test[@]} functions to test"

# check if tester exist
if [[ -f $tester_file_name ]]; then
    if gr.ask "tester '$tester_file_name' exist, overwrite?"; then
        gr.msg "overwriting.."
    else
        gr.msg "canceling.."
        exit 12
    fi
fi

cat >$tester_file_name <<EOL
#!/bin/bash
# automatically generated tester for grbl $module.sh $(date)

# sourcing and test variable space
source \$GRBL_BIN/common.sh
source $module_to_test

# visibility settings
export GRBL_COLOR=true
export GRBL_VERBOSE=2

# add test initial conditions here
gr.msg -v3 -e1 "initial conditions not written"

testNr=1
results=()
results[0]="result:function:arguments:return:note"

runf () {
# result pass/fail handler

    local arguments=()
    local manualMsg=()
    local passCond=0
    local function=

    # getop or getops cannot get string arguments for options, therefore following..
    local m=
    local p=
    for arg in \$@; do
        case \$arg in
            -m) m=true
                p=
                continue
                ;;
            -p) p=true
                m=
                continue
                ;;
        esac

        if [[ \$m ]]; then
            manualMsg+=("\$arg")
        elif [[ \$p ]]; then
            passCond=\$arg
        else
            if [[ \$function ]]; then
                arguments+=("\$arg")
            else
                function=\$arg
            fi
        fi
    done


    gr.msg -N -n -h "Test: \$testNr - "
    gr.msg -c white "$module.\$function \${arguments[@]}"

    $module.\$function \${arguments[@]}

    returnValue=\$?

    [[ -f /tmp/\$USER/ask.comment ]] && rm /tmp/\$USER/ask.comment
    if [[ \$manualMsg ]]; then
        if gr.ask "\${manualMsg[@]}"; then
            reurnValue=0
        else
            local comment=\$(cat /tmp/\$USER/ask.comment)
            if [[ \$comment ]]; then
                returnValue=254
            else
                returnValue=255
            fi
        fi
    fi

    gr.msg -n -h "Result of test \$testNr: "
    if [[ \$returnValue -eq \$passCond ]]; then
        gr.msg -c green "PASSED"
        results[\$testNr]="p:\$function:\${arguments[@]}:\$returnValue:clean result"

    elif [[ \$returnValue -gt 1 ]] && [[ \$returnValue -lt 9 ]]; then
        gr.msg -e1 "WARNING"
        results[\$testNr]="w:\$function:\${arguments[@]}:\$returnValue:warning"

    elif [[ \$returnValue -eq 127 ]]; then
        gr.msg -e2 "NO RESULT"
        results[\$testNr]="e:\$function:\${arguments[@]}:\$returnValue:non existing, check case"

    elif [[ \$returnValue -eq 254 ]]; then
        gr.msg -n -c fail "FAILED"
        gr.msg -e1 " with comment"
        results[\$testNr]="c:\$function:\${arguments[@]}:\$returnValue:\$comment"

    elif [[ \$returnValue -gt 99 ]] && [[ \$returnValue -lt 256 ]]; then
        gr.msg -c fail "FAILED"
        results[\$testNr]="f:\$function:\${arguments[@]}:\$returnValue:non zero result"

    else
        gr.msg -e1 "NO RESULT"
        results[\$testNr]="e:\$function:\${arguments[@]}:\$returnValue:error in test case"
    fi

    let testNr++
}

runc () {
# run list of cases

    local cases=(\$@)

    for case in \${cases[@]}; do

        case \$case in
            all)
                while read case; do
                    runf "\$case"
                done <$module.tc
                ;;
            [1-9]|[1-9][0-9]|[1-9][0-9][0-9])

                runf \$(head -\$case $module.tc | tail +\$case)
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

    # echo "\${#results[@]}:\${results[@]}"

    gr.msg -N -h "Results \$(date -d today +\${GRBL_FORMAT_DATE}_\${GRBL_FORMAT_TIME})"
    for (( i = 1; i < \${#results[@]}; i++ )); do

        gr.msg -n -h -w 4 "\$i: "
        case \$(cut -d ':' -f 1 <<<\${results[\$i]}) in
            p)
                gr.msg -w 10 -n -c green "PASSED "
                gr.msg -w 15 -n -c light_blue "\$(cut -d ':' -f 2 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c gray "\$(cut -d ':' -f 3 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c white "\$(cut -d ':' -f 5 <<<\${results[\$i]}) "
                gr.msg -w 4 -n -c gray "\$(cut -d ':' -f 4 <<<\${results[\$i]}) "
                let passes++
                ;;
            f)
                gr.msg -w 10 -n -c fail "FAILED "
                gr.msg -w 15 -n -c light_blue "\$(cut -d ':' -f 2 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c gray "\$(cut -d ':' -f 3 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c white "\$(cut -d ':' -f 5 <<<\${results[\$i]}) "
                gr.msg -w 4 -n -c grey "\$(cut -d ':' -f 4 <<<\${results[\$i]}) "
                let fails++
                ;;
            w)
                gr.msg -w 10 -n -e1 "PASSED "
                gr.msg -w 15 -n -c light_blue "\$(cut -d ':' -f 2 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c gray "\$(cut -d ':' -f 3 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c white "\$(cut -d ':' -f 5 <<<\${results[\$i]}) "
                gr.msg -w 4 -n -c grey "\$(cut -d ':' -f 4 <<<\${results[\$i]}) "
                let warnings++
                let passes++
                ;;
            c)
                gr.msg -w 10 -n -c fail "FAILED "
                gr.msg -w 15 -n -c light_blue "\$(cut -d ':' -f 2 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c gray "\$(cut -d ':' -f 3 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -e1 "\$(cut -d ':' -f 5 <<<\${results[\$i]}) "
                gr.msg -w 4 -n -c grey "\$(cut -d ':' -f 4 <<<\${results[\$i]}) "
                let warnings++
                let failes++
                ;;
            e|*)
                gr.msg -w 10 -n -e2 "NO RESULT "
                gr.msg -w 15 -n -c light_blue "\$(cut -d ':' -f 2 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c gray "\$(cut -d ':' -f 3 <<<\${results[\$i]}) "
                gr.msg -w 35 -n -c white "\$(cut -d ':' -f 5 <<<\${results[\$i]}) "
                gr.msg -w 4 -n -c grey "\$(cut -d ':' -f 4 <<<\${results[\$i]}) "
                let errors++
                ;;
        esac
        echo

    done
    gr.msg -h "Summary: \$passes passed, \$fails fails, \$warnings warnings and \$errors with no result"

}

case_parcer () {
# parse cases

    local input=(\$@)
    local cases=()
    local p=0

    for (( i = 0; i < \${#input[@]}; i++ )); do
        case \${input[\$i]} in
            *-*)
                local first=\$(cut -d '-' -f1 <<<\${input[\$i]})
                local last=\$(cut -d '-' -f2 <<<\${input[\$i]})
                if ! [[ \$last ]] || ! [[ \$last ]] || [[ \$last -lt \$first  ]] ; then
                    gr.msg -e1 "please form-to" >&2
                    return 1
                fi
                gr.debug "adding cases \$first to \$last: " >&2
                for (( ii = \$first; ii <= \$last; ii++ )); do
                    cases[\$p]=\$ii
                    let p++
                done
                ;;
            [1-9]|[1-9][0-9]|[1-9][0-9][0-9])
                cases[\$p]=\${input[\$i]}
                let p++
                ;;
            *)
                gr.msg -e1 "skipping '\${input[\$i]}'" >&2
        esac
    done
    gr.debug "cases: \${cases[@]}" >&2
    echo \${cases[@]}
    return \$?
}


# function and tests 1-9
$module.test() {
    local batch=\$1
    shift
    local _results=()
    local _cases=()
    case \$batch in
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
            _cases=(\$(case_parcer \$@))
            runc \${_cases[@]}
            ;;

        cases|tc)
            # run all cases
            runc all
            ;;

        all)
        # all tests = all functions in introduction order
        # TODO: remove non wanted functions and check run order.

EOL

# TODO change following to use common error delivery result print
_i=100
for _function in "${functions_to_test[@]}" ; do
    test_function_name=${_function//"$module."/"$module.test_"}
    (( _i++ ))
    printf "\t\t\techo ; $test_function_name"' || _err=("${_err[@]}" "'"$_i"'") \n' >> $tester_file_name
done

cat >>$tester_file_name <<EOL
            ;;
        # no case and close function
        *) gr.msg "test case $batch not written"
            return 1
    esac
}

EOL

# test function processor
for _function in "${functions_to_test[@]}" ; do
    test_function_name=${_function//"$module."/"$module.test_"}
    gr.msg -v3 -c light_blue "$_function"
    gr.msg -v3 -c light_green "$test_function_name"

    cat >>$tester_file_name <<EOL
$test_function_name () {
# function to test $module module function $_function

    local _error=0
    gr.msg -v0 -c white testing $_function

    ## TODO: add pre-conditions here

    $_function ; _error=\$?

    ## TODO: add analysis here and manipulate $_error

    if  ((_error<1)) ; then
        gr.msg -v0 -c green $_function passed
        return 0
    else
        gr.msg -v0 -c red $_function failed
        return $_error
    fi
}

EOL
done

# add lonely runner check
cat >>$tester_file_name <<EOL

if [[ \${BASH_SOURCE[0]} == \${0} ]]; then
    source \$GRBL_RC
    GRBL_VERBOSE=2
        $module.test \$@
fi
EOL

chmod +x "$tester_file_name"

# open for edit
$GRBL_PREFERRED_EDITOR $tester_file_name