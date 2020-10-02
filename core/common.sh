# guru-client common functions
# TODO remove common.sh, not practical way cause of namespacing

system.core-dump () {
    echo "core dumped to $GURU_CORE_DUMP"
    set > "$GURU_CORE_DUMP"
}

poll_order() {
    local i=0 ;  while [ "$i" -lt "${#GURU_DAEMON_POLL_LIST[@]}" ] && [ "${GURU_DAEMON_POLL_LIST[$i]}" != "$1" ] ; do ((i++)); done ; ((i=i+1)) ; echo $i;
}

export -f system.core-dump
source $GURU_BIN/os.sh
source $GURU_BIN/deco.sh
source $GURU_BIN/counter.sh

