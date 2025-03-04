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

if [[ -f $script ]] || [[ -f $config ]]; then
	echo "'$module_name' script or config already exist, canceling.."
	exit 1
fi

cp $template_script $script
cp $template_config $config

sed -i -e "s/modulename/$module_name/g" $script
sed -i -e "s/MODULENAME/${module_name^^}/g" $script
sed -i -e "s/YEAR/$(date -d today +%Y)/g" $script
sed -i -e "s/EMAIL/$GRBL_USER_EMAIL/g" $script

sed -i -e "s/modulename/$module_name/g" $config
sed -i -e "s/MODULENAME/${module_name^^}/g" $config

read -p "Remove commentation? " ans
case $ans in
	y|Y)
		sed -i '/#:/d' $script
		sed -i '/#:/d' $config
esac

read -p "Remove debug lines? " ans
case $ans in
	y|Y)
		sed -i '/# DEBUG/d' $script
		sed -i '/# DEBUG/d' $config
esac

read -p "copy config to '$GRBL_CFG/$GRBL_USER' ? " ans
case $ans in
	y|Y)
		cp $config $GRBL_CFG/$GRBL_USER
esac

# make tester
read -p "make tester? " ans
case $ans in
	y|Y)
		cases="1-6"
		cd "../test/"
		./build-tester.sh $module_name
		template_tc="../templates/template.tc"
		cp $template_tc "../test/$module_name.tc"

		read -p "run test cases $cases? " ans
		case $ans in
			y|Y)
				./test-$module_name.sh c $cases
		esac
esac

echo
echo "Generated files for $module_name module"
echo "  script:  $script"
echo "  config:  $config"
echo "  tester:  ../test/test-$module_name.sh"
echo "  cases:   ../test/$module_name.tc"
echo
echo "- add '$module_name' to 'install.sh' 'modules_to_install' list"
echo "- run tests: go to '../test' folder and run './test-$module_name.sh c $cases'"
