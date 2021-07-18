#!/bin/bash

# "$1" must be a "$x,$y" pair.
# "$2" is an attr to get.

if [[ -z "$2" || ! -z "$3" ]]; then
	echo "obj_getattr(): wrong number of arguments."
	echo "Usage: <int:x>,<int:y> <string:attrtype>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_getattr(): game not launched."
	source shutdown.sh error
fi

# Convert argument type string to lowercase:
ATTR=$(echo "$2" | sed 's/\(.*\)/\L\1/')	#'# For the MC colorer.

PROPSSTR="${CLASSPROPS[${OBJECTS[$1]}]}"

case "$2" in
	"symbol"|"symb")
		echo "$PROPSSTR" | cut $CLASS_SYMBOL
		;;
	"hp"|"health")
		echo "${OBJECTSHP[$1]}"
		;;
	"maxhp"|"maxhealth")
		echo "$PROPSSTR" | cut $CLASS_MAXHP
		;;
	"cost"|"price")
		echo "$PROPSSTR" | cut $CLASS_COST
		;;
	"range"|"speed")
		echo "$PROPSSTR" | cut $CLASS_RANGE
		;;
	"attack"|"atk"|"damage")
		echo "$PROPSSTR" | cut $CLASS_ATK
		;;
	"backfire"|"batk")
		echo "$PROPSSTR" | cut $CLASS_BATK
		;;
	"color")
		echo "${OBJECTSCOLOR[$1]}"
		;;
	"team")
		echo $(( "${OBJECTSCOLOR[$1]}" % 10 ))
		;;
	"possibleteams"|"teams")
		echo "${CLASSTEAMS[${OBJECTS[$1]}]}"
		;;
	"attr"*)
		echo "${CLASSATTRS[${OBJECTS[$1]}]}"
		;;
	*)
		echo "Warning: unknown property \"$2\"."
		;;
esac

unset PROPSSTR
unset ATTR
