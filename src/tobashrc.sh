
## guru launcher
if [ -f ~/.gururc ]; then
    . ~/.gururc
fi

## guru enabled
function gio.enable () {
	if [ -f "$HOME/.gururc.disabled" ]; then 
		mv "$HOME/.gururc.disabled" "$HOME/.gururc" 
		echo "giocon.client enabled"
	else
		echo "enabling failed"
	fi
}

export -f gio.enable