#!/bin/bash
# path set here based on user.cfg information 

declare -A prompt

source $GURU_CFG/prompt.cfg
[[ -f $GURU_CFG/$GURU_USER/prompt.cfg ]] && source $GURU_CFG/$GURU_USER/prompt.cfg


if [[ ${prompt[enabled]} ]] && [[ $GURU_FLAG_COLOR ]]; then

	PS1=${debian_chroot:+($debian_chroot)}

	_c_var="C_${prompt[user]^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]\u"

	_c_var="C_${prompt[at]^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]@"

	_c_var="C_${prompt[host]^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]\h"

	_c_var="C_${prompt[project]^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]#$GURU_PROJECT_NAME"

	_c_var="C_${prompt[folder]^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]:\w"

	_c_var="C_${prompt[text]^^}"
	_color_code=${!_c_var}
	PS1="$PS1\[$(printf %s $_color_code)\]$ "

else
	export PS1='${debian_chroot:+($debian_chroot)}\u@\h#$GURU_PROJECT_NAME:\w$ '
fi
