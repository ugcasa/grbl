
conda.install () {

	conda list && return 13 || echo "no conda installed"

	sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6

	[ "$1" ] && conda_version=$1 || conda_version="2019.03"
	conda_installer="Anaconda3-$conda_version-Linux-x86_64.sh"
	conda_sum=45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a

	curl -O https://repo.anaconda.com/archive/$conda_installer
	sha256sum $conda_installer >installer_sum
	printf "checking sum, if exit it's invalid: "
	cat installer_sum |grep $conda_sum && echo "ok" || return 11

	chmod +x $conda_installer
	bash $conda_installer -u && rm $conda_installer installer_sum || return 12
	source ~/.bashrc 
	echo 'conda install done, next run setup by typing: "'$GURU_CALL' set conda"'
	return 0
}


conda.launch () {
	conda_setup="$('$GURU_BIN/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
	    eval "$conda_setup"
	else
	    if [ -f "$GURU_BIN/conda/etc/profile.d/conda.sh" ]; then
	        source "$GURU_BIN/conda/etc/profile.d/conda.sh"
	    else
	        export PATH="$GURU_BIN/conda/bin:$PATH"
	    fi
	fi	
}