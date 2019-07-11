#!/bin/bash
# note generator


cfg="$HOME/.gururc"

[[ -f "$cfg" ]] && . $cfg || exit 17
[[ -z "$1" ]] && teamName="ujo.guru" || teamName="$1"

templateDir="$GURU_NOTES/$GURU_USER/template"
templateFile="template.$GURU_USER.$teamName.md"

template="$templateDir/$templateFile"
noteDir=$GURU_NOTES/$GURU_USER/$(date +%Y/%m)
noteFile=$GURU_USER"_notes_"$(date +%Y%m%d).md
note="$noteDir/$noteFile"

[[  -d "$noteDir" ]] || mkdir -p "$noteDir"

if [[ ! -f "$note" ]]; then 	    
	    printf "$noteFile $(date +%H:%M:%S)\n\n# Muistiinpanot $(date +%-d.%-m.%Y)\n\n" >$note
	    echo "notesfile = $noteFile"
	    if [[ -f "$template" ]]; then 
	        cat "$template" >>$note
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

