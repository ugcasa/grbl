#!/bin/bash
# ujo.guru tool kit environmental variables
# called from .bashrc every time bash session starts
#export GURU_USER=casa
# basic locations
export GURU_BIN="$HOME/bin"
export GURU_CFG="$HOME/.config/guru"
export GURU_USER_RC="$GURU_CFG/$GURU_USER/userrc"

# user configurtation
if [ -f "$GURU_USER_RC" ]; then 					# if user setting file exist
	source "$GURU_USER_RC"							# execute personal settings
else 												# Defaults
	source "$GURU_CFG/templaterc"	 				# execute personal defaults
fi

#alias "$GURU_CALL"=$GURU_BIN/guru

