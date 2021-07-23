#!/bin/bash

# "$1" must be a "$x,$y" pair.
# "$2" is an attr to get.

if [[ -z "$2" || "$3" ]]; then
	echo "obj_getattr(): wrong number of arguments."
	echo "Usage: <int:x>,<int:y> <string:attrtype>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_getattr(): game not launched."
	source shutdown.sh error
fi

# Convert argument type string to lowercase:
declare -l ATTR="$2"

case "$2" in
	"symb"*)
		echo "${CLASSPROPS[${OBJECTS[$1]}:symb]}"
		;;
	"maxhp"|"maxhealth")
		echo "${CLASSPROPS[${OBJECTS[$1]}:maxhp]}"
		;;
	"cost"|"price")
		echo "${CLASSPROPS[${OBJECTS[$1]}:cost]}"
		;;
	"range"|"speed")
		echo "${CLASSPROPS[${OBJECTS[$1]}:range]}"
		;;
	"attack"|"atk"|"damage")
		echo "${CLASSPROPS[${OBJECTS[$1]}:atk]}"
		;;
	"backfire"|"batk")
		echo "${CLASSPROPS[${OBJECTS[$1]}:batk]}"
		;;
	"team")
		echo "${PLAYERTEAMS[${OBJECTSCOLOR[$1]}]}"
		;;
	"possibleteams"|"teams")
		for (( i_getattr = 1; i_getattr < $MAXPLAYERS; i_getattr++ )); do
			[[ "${TEAMCLASSES[$i_getattr]}" == *"${OBJECTS[$1]}"* ]] && echo "$i_getattr" && break
		done
		;;
	"attr"*)
		echo "${CLASSATTRS[${OBJECTS[$1]}]}"
		;;
	"hp"|"health")
		echo "${OBJECTSHP[$1]}"
		;;
	"color")
		echo "${OBJECTSCOLOR[$1]}"
		;;
	*)
		echo "Warning: unknown property \"$2\"."
		;;
esac

unset ATTR
