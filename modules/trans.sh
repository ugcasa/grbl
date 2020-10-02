#!/bin/bash
# ujo.guru 2019


translate () {
	 # terminal based translator
	 # TODO: bullshit, re-write (handy shit dow, in daily use)

	 if ! [ -f $GURU_BIN/trans ]; then
	 	cd $GURU_BIN
	 	wget git.io/trans
	 	chmod +x ./trans
	fi

	if [[ $1 == *"-"* ]]; then
		argument1=$1
		shift
	else
	  	argument1=""
	fi

	if [[ $1 == *"-"* ]]; then
		argument2=$1
		shift
	else
	  	argument2=""
	fi

	if [[ $1 == *":"* ]]; then
	  	#echo "iz variable: $variable"
		variable=$1
		shift
		word=$@

	else
	  	#echo "iz word: $word"
	  	word=$@
	  	variable=""
	fi

	$GURU_BIN/trans $argument1 $argument2 $variable "$word"

}


trans (){
	# alias, ot just use trans whitout "guru" on front of it
	translate $@
}
