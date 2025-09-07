#!/bin/bash
# Make GRBL bash module out of template

if [[ $1 ]]; then
	module_name="$1"
else
	read -p "module name: " module_name
fi

script="../modules/$module_name.sh"
config="../cfg/$module_name.cfg"
template_script="module_template.sh"
template_config="module_template.cfg"
owsrc=true
owcfg=
owtst=
owtca=

if [[ -f $script ]] ; then
	read -p "overwrite script? " ans
	case $ans in
		y|Y)
			owsrc=true
			rm $script
			echo "making script"
			;;
		*)
			owsrc=
			echo "keeping original"
	esac
fi

# make script
if [[ $owsrc ]]; then 
	# copy template	
	cp $template_script $script

	# change to modulename
	sed -i -e "s/modulename/$module_name/g" $script
	sed -i -e "s/MODULENAME/${module_name^^}/g" $script
	sed -i -e "s/YEAR/$(date -d today +%Y)/g" $script
	sed -i -e "s/EMAIL/$GRBL_USER_EMAIL/g" $script
fi

# check config
if [[ -f $config ]] ; then
	read -p "overwrite configs? " ans
	case $ans in 
		y|Y)
			owcfg=true
			;;
		*)
			echo "keeping original"
			owcfg=
	esac
fi

# make config
if [[ $owcfg ]] || ! [[ -f $config ]] ; then
	cp $template_config $config
	sed -i -e "s/modulename/$module_name/g" $config
	sed -i -e "s/MODULENAME/${module_name^^}/g" $config
fi

read -p "remove instructions? " ans
case $ans in y|Y)
	[[ $owsrc ]] && sed -i '/#:/d' $script
	[[ $owcfg ]] && sed -i '/#:/d' $config
esac

read -p "remove debug lines? " ans
case $ans in y|Y)
	[[ $owsrc ]] && sed -i '/# DEBUG/d' $script
	[[ $owcfg ]] && sed -i '/# DEBUG/d' $config
esac

# copy to user cfg folder
read -p "copy config to user config folder? " ans
case $ans in y|Y)
	cp $config $GRBL_CFG/$GRBL_USER
esac

# make tester
read -p "make tester? " ans
case $ans in y|Y)
	owtst=true
	cases="1-5"
	cd "../test/"
	./build-tester.sh $module_name

	template_tc="../templates/template.tc"
	if [[ -f "../test/$module_name.tc" ]]; then
		gr.msg "$module_name.tc exist, skip"
	else
		cp $template_tc "../test/$module_name.tc"
		owtca=true
	fi
esac

if [[ -f ./test-${module_name}.sh ]]; then
	read -p "run test cases $cases? " ans
	case $ans in y|Y)
		./test-${module_name}.sh c $cases
	esac
fi

echo
echo "Files for $module_name module"

printf "  script:  $script "
[[ $owsrc ]] && printf "(updated)\n" || echo

printf "  config:  $config "
[[ $owcfg ]] && printf "(updated)\n" || echo

printf "  tester:  ../test/test-$module_name.sh "
[[ $owtst ]] && printf "(updated)\n" || echo

printf "  cases:   ../test/$module_name.tc "
[[ $owtca ]] && printf "(updated)\n" || echo

echo
echo "- add '$module_name' to 'install.sh' 'modules_to_install' list"
echo "- run tests: go to '../test' folder and run './test-$module_name.sh c $cases'"

$GRBL_PREFERRED_EDITOR $script $config