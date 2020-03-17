#!/bin/bash
export GURU_CMD="unmount"
mount.sh "$@"
exit $?