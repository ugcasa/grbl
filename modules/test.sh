#!/bin/bash
# guru-client testing functions for all modules
#
# Test case actions             TODO forget this
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

source $GURU_RC
source $GURU_BIN/common.sh

test.main() {
    # main test case parser
    export all_tools=("mount" "remote" "project" "note" "system" "corsair")
    #export GURU_VERBOSE=true
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
    gmsg -v1 -c white "guru-client tester help "
    gmsg -v2
    gmsg -v0 "usage: $GURU_CALL test <tool>|all|release <tc_nr>|all "
    gmsg -v2
    gmsg -v1 -c white "tools:"
    gmsg -v1 " <tool> <tc_nr>|all    all test cases "
    gmsg -v1 " <tool> release        validation tests prints out only results "
    gmsg -v1 " release               run full validation test "
    gmsg -v2
    gmsg -v1 -c white "example:"
    gmsg -v1 " $GURU_CALL test mount 1 "
    gmsg -v1 " $GURU_CALL test remote all "
    gmsg -v1 " $GURU_CALL test release "
    gmsg -v2
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

    [[ "$1" ]] && _tool="$1" || read -r -p "input tool name to test: " _tool
    [[ "$2" ]] && _case="$2" || _case="all"

    _test_id=$(counter.main get guru-client_test_id)
    counter.main add guru-client_test_id
    echo
    HEADER "TEST $_test_id: guru-client $_tool #$_case - $(date)"

    if [[ -f "$GURU_BIN/test/$_tool.sh" ]] ; then
                _lang="sh"
    elif [[ -f "$GURU_BIN/test/$_tool.py" ]] ; then
                _lang="py"
        else
                gmsg "tool '$_tool' not found\n"
                TEST_FAILED "TEST $_test_id $_tool"
                return 10
        fi

    # source function under test
    source $GURU_BIN/test/$_tool.$_lang
    # source tester functions
    source $GURU_BIN/test/test-$_tool.$_lang

    # run test
    $1.test "$_case" ; _error=$?

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
    # printout unit test output
    export GURU_VERBOSE=true

    # do not log to file
    export LOGGING=
    local _tool="$1"
    local _case="$2"

    # time output format
    local TIMEFORMAT='%R'
    msg "loop $_tool #$_case. usage: [1-9|t|n|b|r|q|]. any other key will run test\n"
    while read -n 1 -e -p "$_tool:$_case > " _cmd; do

        case $_cmd in
          # change case number
          [1-9])  _case=$_cmd                       ;;
              # change tool to test
              t)  local _pre_tool=$_tool ; read -r -p "change tool: " _tool
                  [ -f $GURU_BIN/test/$_tool.sh ] || _tool=$_pre_tool;;
              # next case
              n)  ((_case<9)) && _case=$((_case+1)) ;;
              # previous case
              b)  ((_case>1)) && _case=$((_case-1)) ;;
              # quit
              q)  return 0                          ;;
              # next line  open new terminal
              r)  gnome-terminal -- /bin/bash -c $GURU_CALL' test loop '$_tool' '$_case'; exec bash' ;;
              # prevent note wrong commands
              *)  printf "${RED}$_cmd${NC}\n"
          esac

          # source user settings
          source $HOME/.gururc
          # source function under test
          source $GURU_BIN/test/$_tool.sh
          # source tester functions
          source $GURU_BIN/test/test-$_tool.sh

          # if case not given
          if [ "$_case" ]; then
              # run test tool directly
              time "$_tool.test" "$_case"
            else
              # else run tool test main parser
              time "test.main" "$_tool" "$_case"
          fi
        # to prevent too fast input
        sleep 0.2
      done
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        loop) shift ; test.terminal $@ ; exit $? ;;
        esac
    test.main "$@"
    exit "$?"
fi
