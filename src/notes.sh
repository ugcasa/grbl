#!/bin/bash
# note generator

cfg="$HOME/.gururc"

[[ -f "$cfg" ]] && . $cfg || exit 17
[[ -z "$1" ]] && userName="$USER" || userName="$1"
[[ -z "$2" ]] && teamName="ujo.guru" || teamName="$2"

templateDir="$GURU_NOTES/$userName"
templateFile="template.$userName.$teamName.md"
template="$templateDir/$templateFile"
noteDir="$GURU_NOTES/$userName/$(date +%Y/%m)"
noteFile="$userName"_notes_$($GURU_BIN/gio.datestamp $teamName).md
note="$noteDir/$noteFile"

[[  -d "$noteDir" ]] || mkdir -p "$noteDir"

if [[ ! -f "$note" ]]; then 
	    echo "$noteFile" >"$note"
	    if [[ -f "$template" ]]; then 
	        cat "$template" >>"$note" 
	    else 
	        echo "Template file missing"  
	    fi
fi

if [ $GURU_EDITOR == "subl" ]; then 
	subl --project "$HOME/Dropbox/Notes/casa/project/notes.sublime-project" -a # TODO dropbox folder from config
	subl "$note" --project "$HOME/Dropbox/Notes/casa/project/notes.sublime-project" -a 
else
	$GURU_EDITOR "$note" 
fi

