#!/bin/bash
# path set here based on user.cfg information 

if [[ $GURU_PATH_COLOR_ENABLED ]] && [[ $GURU_FLAG_COLOR ]]; then
	source $GURU_BIN/common.sh
	PS1=${debian_chroot:+($debian_chroot)}
	PS1="$PS1\[$(gmsg -n -C $GURU_PATH_COLOR_USER)\]\u"
	PS1="$PS1\[$(gmsg -n -C $GURU_PATH_COLOR_HOST)\]@\h"
	PS1="$PS1\[$(gmsg -n -C $GURU_PATH_COLOR_PROJECT)\]#$GURU_PROJECT_NAME"
	PS1="$PS1\[$(gmsg -n -C $GURU_PATH_COLOR_FOLDER)\]:\w"
	export PS1="$PS1\[$(gmsg -n -C $GURU_PATH_COLOR_TEXT)\]$ "
else
	export PS1='${debian_chroot:+($debian_chroot)}\u@\h#$GURU_PROJECT_NAME:\w$ '
fi
