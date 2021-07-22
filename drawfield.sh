#!/bin/bash

if [[ "$4" ]]; then
	echo "drawfield(): wrong number of arguments."
	echo "Usage: [<string:whattodo>=\"\"] [<int:x>,<int:y>]."
	echo "\"<string:whattodo>\" is \"default\" (or \"\"), \"updatecache\", \"objectshp\" or \"noobjects\"."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "drawfield(): game not launched."
	source shutdown.sh error
fi


# Only updating field layer cache:
if [[ "$1" == "updatecache" || ( -z ${CACHEFIELD[exists]+x} ) ]]; then
	COORDS="$2"

	# Force full update if there's no field cache:
	[ -z ${CACHEFIELD[exists]+x} ] && declare -g -A CACHEFIELD=( [exists]="yes" ) && COORDS=""

	# Full update if no coordinate presented:
	if [[ -z "$COORDS" ]]; then
		for (( y = 0; y < $FIELDMAXY; y++ )); do
			for (( x = 0; x < $FIELDMAXX; x++ )); do
				CACHEFIELD[$y,$x]=$(echo -ne ${TILES[${FIELD[$y,$x]}]})
			done
		done
	else
		CACHEFIELD[$COORDS]=$(echo -ne ${TILES[${FIELD[$COORDS]}]})
	fi

	# Return without drawing.
	return
fi


echo -ne "\e[?25l" # Hides cursor.

if [ -z "$2" ]; then
	# Full map drawing.

	# Field layer:
	for (( y = 0; y < $FIELDMAXY; y++ )); do
		echo -ne "\e[$((y + $SCREENMINY));${SCREENMINX}H"

		for (( x = 0; x < $FIELDMAXX; x++ )); do
			echo -n "${CACHEFIELD[$y,$x]}"
		done
	done

	# Objects layer:
	if [[ "$1" == "objectshp" ]]; then
		for curObj in "${!OBJECTS[@]}"; do
			CELLY=$(( ${curObj%,*} + $SCREENMINY ))
			CELLX=$(( ${curObj#*,} + $SCREENMINX ))
			echo -ne "\e[$CELLY;${CELLX}H"
			echo -ne "\e[${OBJECTSCOLOR[$curObj]}m${OBJECTSHP[$curObj]}\e[0m"
		done
	elif [[ "$1" != "noobjects" ]]; then
		for curObj in "${!OBJECTS[@]}"; do
			CELLY=$(( ${curObj%,*} + $SCREENMINY ))
			CELLX=$(( ${curObj#*,} + $SCREENMINX ))
			echo -ne "\e[$CELLY;${CELLX}H"
			echo -ne "\e[${OBJECTSCOLOR[$curObj]}m$(. obj_getattr.sh $curObj symbol)\e[0m"
		done
	fi
else
	# One cell drawing.
	CELLY=$(( ${2%,*} + $SCREENMINY ))
	CELLX=$(( ${2#*,} + $SCREENMINX ))
	echo -ne "\e[$CELLY;${CELLX}H"

	if [[ "$1" == "objectshp" && "${OBJECTS[$2]}" ]]; then
		echo -ne "\e[${OBJECTSCOLOR[$2]}m$((32#${OBJECTSHP[$2]}))\e[0m"
	elif [[ "$1" != "noobjects" && "${OBJECTS[$2]}" ]]; then
		echo -ne "\e[${OBJECTSCOLOR[$2]}m$(. obj_getattr.sh $2 symbol)\e[0m"
	else
		echo -ne "${CACHEFIELD[$2]}"
	fi
fi

