# guru-client common functions
# TODO remove common.sh, not practical way cause of namespacing

system.core-dump () {
    echo "core dumped to $GURU_CORE_DUMP"
    set > "$GURU_CORE_DUMP"
}


export -f system.core-dump
source $GURU_BIN/lib/os.sh
source $GURU_BIN/lib/deco.sh
source $GURU_BIN/counter.sh

