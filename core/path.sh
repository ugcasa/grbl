#!/bin/bash
# path set here based on user.cfg information 


if [[ $GURU_PATH_COLOR_ENABLED ]] && [[ $GURU_FLAG_COLOR ]]; then
	# source $GURU_BIN/common.sh
	PS1=${debian_chroot:+($debian_chroot)}

	_c_var="C_${GURU_PATH_COLOR_USER^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]\u"

	_c_var="C_${GURU_PATH_COLOR_HOST^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]@\h"

	_c_var="C_${GURU_PATH_COLOR_PROJECT^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]#$GURU_PROJECT_NAME"

	_c_var="C_${GURU_PATH_COLOR_FOLDER^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]:\w"

	_c_var="C_${GURU_PATH_COLOR_TEXT^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]$ "

else
	export PS1='${debian_chroot:+($debian_chroot)}\u@\h#$GURU_PROJECT_NAME:\w$ '
fi
