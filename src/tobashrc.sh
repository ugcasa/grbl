
## giocon launcher
if [ -f ~/.gururc ]; then
    . ~/.gururc
fi

## giocon enabled
function gio.enable () {
	if [ -f "$HOME/.gururc.disabled" ]; then 
		mv "$HOME/.gururc.disabled" "$HOME/.gururc" 
		echo "giocon.client enabled"
	else
		echo "enabling failed"
	fi
}

export -f gio.enable