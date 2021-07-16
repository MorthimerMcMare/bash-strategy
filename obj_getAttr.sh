#!/bin/bash

# "$1" must be a "$x,$y" pair.
# "$2" is an attr to get.

if [[ -z "$1" ]]; then
	echo "Error: cannot get/set attribute from emply place."
	exit
fi

ATTR=$(echo "$2" | sed 's/\(.*\)/\L\1/')	# ' # For MC colorer.

case "$2" in
	"symbol"|"symb")
		echo "${OBJECTS[$1]}" # !!!
		;;
	"hp"|"health")
		echo "${OBJECTSHP[$1]}"
		;;
	"maxhp"|"maxhealth")
		echo "${OBJECTS[$1]}" # !!!
		;;
	"cost"|"price")
		;;
	"range"|"speed")
		;;
	"attack"|"atk"|"damage")
		;;
	"backfire"|"batk")
		;;
	"attr*")
		;;
	*)
		echo "Warning: unknown property \"$2\"."
		;;
esac



