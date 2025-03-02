#!/bin/bash
# make test
# TODO omg how old ways to do shit, review pls.

source $GRBL_BIN/common.sh

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
        return 12
    fi

gr.msg -c white "generating tester for $module_to_test"
# inldes only if space is left between function name and "()" TEST space removed!
functions_to_test=($(cat $module_to_test |grep "()" |cut -f1 -d " "))
tester_file_name="test-""$module"".sh"

gr.msg -v1 -c blue "module: $module_to_test"
gr.msg -v1 -c blue "output: $tester_file_name"
gr.msg "${#functions_to_test[@]} functions to test"

# check if tester exist
if [[ -f $tester_file_name ]] && gr.ask "tester '$tester_file_name' exist, overwrite?" ; then
            gr.msg "overwriting.."
        else
            gr.msg "canceling.."
            return 12
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
ge.msg -v3 -e1 "initial conditions not written"

# result pass/fail handler
testN=0
results=()

result() {
# pass if 0 of 1, pass statuses 2 - 9 and fail 10 - 255

    local returnValue=$1
    shift

    local reason=$@

    if [[ \$returnValue -eq 0 ]]; then
        result[\$testN]="passsed:\$returnValue:clean result"
    elif [[ \$returnValue -eq 1 ]]; then
        result[\$testN]="passsed:\$returnValue:retuned false"
    elif [[ \$returnValue -gt 1 ]] && [[ \$returnValue -lt 9 ]]; then
        result[\$testN]="warings:\$returnValue:warning \$reason"
    elif [[ \$returnValue -gt 99 ]] && [[ \$returnValue -lt 255 ]]; then
        result[\$testN]="failed:\$returnValue:\$reason"
    else
        result[\$testN]="error:\$returnValue:error in test case"
    fi

    let test_nr++
}



# function and tests 1-9
$module.test() {
    local test_case=\$1
    local results=()
    case "$test_case" in
      1)
          $module.main status || results+=(11)
          $module.main nonvalidinput && results+=(12)
          $module.help || results+=(13)
          $module.rc || results+=(14)
          $module.makerc || results+=(15)
          $module.status || results+=(16)
          $module.help || results+=(17)
          ;;
      9)
          # these tests install and remove module requirements
          # be sure that installer/uninstallers do not harm hot environment
          gr.ask "run install/remove tests?" || return 0
          $module.install && || p:91 || results+=(f:91)
          $module.remove || results+=(f:92)
          gr.ask "install module requirements to be able to continue tests?" || return 0
          $module.install || results+=(f:93)
          ;;


EOL

# all tests = all functions in introduction order
printf '\t\t\tall) \n' >> $tester_file_name
printf '\t\t\t\t# TODO: remove non wanted functions and check run order. \n'>> $tester_file_name
_i=100
for _function in "${functions_to_test[@]}" ; do
    test_function_name=${_function//"$module."/"$module.test_"}
    (( _i++ ))
    echo "\t\t\techo ; $test_function_name"' || _err=("${_err[@]}" "'"$_i"'") \n' >> $tester_file_name
done

# no case and close function
printf '\t\t\t*) gr.msg "test case $test_case not written"\n' >> $tester_file_name
printf '\t\t\treturn 1\n' >> $tester_file_name
printf '\t\t\tesac\n' >> $tester_file_name
printf '}\n' >> $tester_file_name
echo >> $tester_file_name
# test function processor
for _function in "${functions_to_test[@]}" ; do
    test_function_name=${_function//"$module."/"$module.test_"}
    gr.msg -v2 -c light_blue "$_function"
    gr.msg -v2 -c light_green "$test_function_name"

    echo >> $tester_file_name
    echo  "$test_function_name () {" >> $tester_file_name
    echo "    # function to test $module module function $_function" >> $tester_file_name
    printf '    local _error=0\n' >> $tester_file_name
    echo "    gr.msg -v0 -c white 'testing $_function'" >> $tester_file_name
    echo >> $tester_file_name
    printf '      ## TODO: add pre-conditions here \n' >> $tester_file_name
    echo >> $tester_file_name
    echo "      $_function"' ; _error=$?' >> $tester_file_name
    echo >> $tester_file_name
    printf '      ## TODO: add analysis here and manipulate $_error \n' >> $tester_file_name
    echo >> $tester_file_name
    printf '    if  ((_error<1)) ; then \n' >> $tester_file_name
    echo "       gr.msg -v0 -c green '$_function passed' " >> $tester_file_name
    printf '       return 0\n' >> $tester_file_name
    printf '    else\n' >> $tester_file_name
    echo "       gr.msg -v0 -c red '$_function failed' " >> $tester_file_name
    printf '       return $_error\n' >> $tester_file_name
    printf '  fi\n' >> $tester_file_name
    echo "}" >> $tester_file_name
    echo >> $tester_file_name
done

# add lonely runner check
echo >> $tester_file_name
printf 'if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then \n' >> $tester_file_name
printf '    source "$GRBL_RC" \n' >> $tester_file_name
printf '    GRBL_VERBOSE=2\n' >> $tester_file_name
echo "    $module.test "'$@' >> $tester_file_name
printf 'fi\n' >> $tester_file_name
echo >> $tester_file_name

# make runnable
chmod +x "$tester_file_name"
# open for edit
$GRBL_PREFERRED_EDITOR $tester_file_name