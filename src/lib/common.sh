# guru tool-kit common functions

msg() {
    # function for ouput messages and make log notifications.
    if ! [[ "$1" ]] ; then return 0 ; fi                            # if no message, just return
    printf "$@" >"$GURU_ERROR_MSG" ;                                # keep last message to las error
    if [[ "$GURU_VERBOSE" ]] ; then printf "$@" ; fi                # print out if verbose set
    if ! [[ -f "$GURU_LOCAL_TRACK/.online" ]] ; then return 0 ; fi  # check that system mount is online before logging
    if ! [[ -f "$GURU_LOG" ]] ; then return 0 ; fi                  # log inly is log exist (hmm.. this not really neede)
    if [[ "$LOGGING" ]] ; then                                      # log without colorcodes ets.
        printf "$@" | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi
}


system.core-dump () {
    echo "core dumped to $GURU_CORE_DUMP"
    set > "$GURU_CORE_DUMP"
}


export -f msg system.core-dump
source $GURU_BIN/lib/os.sh
source $GURU_BIN/lib/deco.sh
source $GURU_BIN/counter.sh

