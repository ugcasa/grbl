#!/bin/bash
# guru-client testing functions for all modules
#
# Test case actions
#  1) quick check
#  2) list stuff
#  3) information or check
#  4) action, test locations
#  5) return
#  6) action, touch hot files
#  7) return
#  all) run all valid tests (selected)
#  release) release validation tests
#  clean) make clean
source $HOME/.gururc
source $HOME/.gururc2
source $GURU_BIN/lib/common.sh

test.main() {
    # main test case parser
    export all_tools=("mount" "remote" "project" "note" "system")
    export GURU_VERBOSE=true
    export LOGGING=true

    case "$1" in
        snap|quick) test.all 1              ; return $? ;;
            *[1-9]) test.all "$1"           ; return $? ;;
               all) time test.all           ; return $? ;;
           release) test.release            ; return 0  ;;
        help|-h|"") test.help               ; return 0  ;;
        *)          test.tool $@            ; return $? ;;
    esac
}


test.help () {
    echo "-- guru-client main test help -------------------------------------"
    printf "usage:\t %s test <tool>|all|release <tc_nr>|all   \n" "$GURU_CALL"
    printf "\ntools:\n"
    printf " <tool> <tc_nr>|all     all test cases \n"
    printf " <tool> release        validation tests prints out only results \n"
    printf " release               run full validation test \n"
    printf "\nexample:"
    printf "\t %s test mount 1 \n" "$GURU_CALL"
    printf "\t\t %s test remote all \n" "$GURU_CALL"
    printf "\t\t %s test release \n" "$GURU_CALL"
    return 0
}


test.tool() {
    # Tool to test tools. Simply call sourced tool main function and parse normal commands
    # sources under test

    local _tool=""
    local _case=""
    local _lang=""
    local _test_id=""
    local _error=0

    [ "$1" ] && _tool="$1" || read -r -p "input tool name to test: " _tool
    [ "$2" ] && _case="$2" || _case="all"

    _test_id=$(counter.main get guru-client_test_id)
    counter.main add guru-client_test_id
    echo
    HEADER "TEST $_test_id: guru-client $_tool #$_case - $(date)"

    if [ -f "$GURU_BIN/$_tool.sh" ]; then
                _lang="sh"
    elif [ -f "$GURU_BIN/$_tool.py" ]; then
                _lang="py"
        else
                gmsg "tool '$_tool' not found\n"
                TEST_FAILED "TEST $_test_id $_tool"
                return 10
        fi

    source $GURU_BIN/$_tool.$_lang                              # source function under test
    source $GURU_BIN/test/test-$_tool.$_lang                         # source tester functions

    $1.test "$_case" ; _error=$?                        # run test

    if ((_error==1)) ; then
         TEST_IGNORED "TEST $_test_id $_tool.$_lang"
        return 0
        fi

    if ((_error<1)) ; then
            TEST_PASSED "TEST $_test_id $_tool.$_lang"
            return 0
        else
            TEST_FAILED "TEST $_test_id $_tool.$_lang"
            return $_error
        fi
}


test.all() {
    # run all module tests and all cases
    local _error=0
    for _tool in ${all_tools[@]}; do
            test.tool $_tool "$1" || _error=$((_error+1))
        done

    if ((_error<1)); then
            PASSED "\nTest run result is"
        else
            msg "counted $_error error(s)\n"
            FAILED "\nTest run result is"
        fi

    return $_error
}


test.release() {
    # validation test, tests all but prints out only module reports
    local _error=0
    local _test_id=$(counter.main add guru-client_validation_test_id)

        msg "\n${WHT}RELEASE TEST $_test_id: guru-client v.$GURU_VERSION $(date)${NC}\n"
        test.all |grep --color=never "result is:" |grep "TEST" || _error=$?

        if ((_error<9)); then
                PASSED "RELEASE $_test_id RESULT"
            else
                msg "last error code were: $_error\n"
                FAILED "RELEASE $_test_id RESULT"
            fi
        return $_error
}

## special functions or unit tests (when run as file)

test.terminal () {
    export GURU_VERBOSE=true                                     # printout unit test output
    export LOGGING=                                         # do not log to file
    local _tool="$1"
    local _case="$2"
    local TIMEFORMAT='%R'                                   # time output format
    msg "loop $_tool #$_case. usage: [1-9|t|n|b|r|q|]. any other key will run test\n"
    while read -n 1 -e -p "$_tool:$_case > " _cmd; do

        case $_cmd in
          [1-9])  _case=$_cmd                       ;;      # change case number
              t)  local _pre_tool=$_tool ; read -r -p "change tool: " _tool
                  [ -f $GURU_BIN/$_tool.sh ] || _tool=$_pre_tool;;      # change tool to test
              n)  ((_case<9)) && _case=$((_case+1)) ;;      # next case
              b)  ((_case>1)) && _case=$((_case-1)) ;;      # previous case
              q)  return 0                          ;;      # quit # next line  open new terminal
              r)  gnome-terminal -- /bin/bash -c $GURU_CALL' test loop '$_tool' '$_case'; exec bash' ;;
              *)  printf "${RED}$_cmd${NC}\n"               # prevent note wrong commands
          esac

          source $HOME/.gururc                              # source user settings
          source $GURU_BIN/$_tool.sh                        # source function under test
          source $GURU_BIN/test/test-$_tool.sh                   # source tester functions

          if [ "$_case" ]; then                             # if case not given
              time "$_tool.test" "$_case"                   # run test tool directly
            else
              time "test.main" "$_tool" "$_case"            # else run tool test main parser
          fi
        sleep 0.2                                           # to prevent too fast input
      done
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        loop) shift ; test.terminal $@ ; exit $? ;;
        esac
    test.main "$@"
    exit "$?"
fi
