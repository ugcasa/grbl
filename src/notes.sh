#!/bin/bash
# giocon note generator

cfg=$HOME/.config/gio/noter.cfg

if [[ -f $cfg ]]; then 
	. $cfg
else 
	echo "config file missing"
	exit 1
fi 

[[ -z "$1" ]] && userName="$USER" || userName="$1"
[[ -z "$2" ]] && teamName="ujo.guru" || teamName="$2"

templateDir="$notes/$userName"
templateFile="template.$userName.$teamName.md"
template="$templateDir/$templateFile"
noteDir="$notes/$userName/$(date +%Y/%m)"
noteFile="$userName"_notes_$(gio.datestamp $teamName).md
note="$noteDir/$noteFile"

if [[ -d "$noteDir" ]]; then 
	echo "Folder $(date +%Y/%m) OK"
	else  
		mkdir -p "$noteDir"
		echo "Creating $noteDir"
	fi

if [[ -f "$note" ]]; then 
    echo "$noteFile exists"
	else 
	    echo "$noteFile" >"$note"
	    if [[ -f "$template" ]]; then 
	        cat "$template" >>"$note" 
	    else 
	        echo "Template file missing"  
	    fi
	fi

if [ "$editor"=="subl" ] || [ "$editor"=="sublime" ]; then
	subl --project "$HOME/Dropbox/Notes/casa/project/notes.sublime-project" -a # TODO dropbox folder from config
	subl "$note" --project "$HOME/Dropbox/Notes/casa/project/notes.sublime-project" -a 
else
	$editor "$note" 

