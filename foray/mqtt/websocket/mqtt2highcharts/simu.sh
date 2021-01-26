
#GURU_VERBOSE=3
source common.sh
source mqtt.sh

# mqtt-send file line by line

file="$1"
[[ -f $file ]] || gmsg -x 100 -c yellow "file do not exists"

while read p; do
	message="${p##* }"
	topic="${p% *}"
	gmsg -v3 -n -c red "$topic "
	gmsg -v3 -c green "$message"
  	mqtt.pub "$topic" "$message"
  	sleep 0.95
done <$file
