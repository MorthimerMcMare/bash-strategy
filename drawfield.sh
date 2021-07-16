#!/bin/bash

if [[ ! -z "$4" ]]; then
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
	CONTINUE=0

	# Force full update if there's no field cache:
	[ -z ${CACHEFIELD+x} ] && declare -g -A CACHEFIELD=( [exists]="yes" ) && COORDS="" && CONTINUE=1
	
	# Full update if no coordinate presented:
	if [[ -z "$COORDS" ]]; then
		for (( y = 0; y < $FIELDMAXY; y++ )); do
			for (( x = 0; x < $FIELDMAXX; x++ )); do
				CACHEFIELD[$y,$x]=$(echo -ne ${TILES[${FIELD[$y,$x]}]})
			done
		done
	else
		CACHEFIELD[$y,$x]=$(echo -ne ${TILES[${FIELD[$y,$x]}]})
	fi

	# Return without drawing.
	(( $CONTINUE == 0 )) && exit
fi


clear # (Temporal).
echo -ne "\e[?25l" # Hide cursor.

if [[ -z "$2" ]]; then
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
			CELLY=$(( $(echo "$curObj" | cut -d"," -f1) + $SCREENMINY ))
			CELLX=$(( $(echo "$curObj" | cut -d"," -f2) + $SCREENMINX ))
			echo -ne "\e[$(($CELLY + $SCREENMINY));$(($(echo "$2" | cut -d"," -f2) + $SCREENMINX))H"
			echo -ne "\e[${OBJECTSCOLOR[$curObj]}m${OBJECTSHP[$curObj]}\e[0m"
		done
	elif [[ "$1" != "noobjects" ]]; then
		for curObj in "${!OBJECTS[@]}"; do
			CELLY=$(( $(echo "$curObj" | cut -d"," -f1) + $SCREENMINY ))
			CELLX=$(( $(echo "$curObj" | cut -d"," -f2) + $SCREENMINX ))
			echo -ne "\e[$CELLY;${CELLX}H"
			echo -ne "\e[${OBJECTSCOLOR[$curObj]}m$(. obj_getattr.sh $curObj symbol)\e[0m"
		done
	fi
else
	# One cell drawing.
	CELLY=$(( $(echo "$2j" | cut -d"," -f1) + $SCREENMINY ))
	CELLX=$(( $(echo "$2" | cut -d"," -f2) + $SCREENMINX ))
	echo -ne "\e[$CELLY;${CELLX}H"

	if [[ "$1" == "objectshp" && ( ! -z ${OBJECTS[$2]} ) ]]; then
		echo -ne "\e[${OBJECTSCOLOR[$2]}m${OBJECTSHP[$2]}\e[0m"
	elif [[ "$1" != "noobjects" && ( ! -z ${OBJECTS[$2]} ) ]]; then
		echo -ne "\e[${OBJECTSCOLOR[$2]}m$(. obj_getattr.sh $2 symbol)\e[0m"		
	else
		echo -n "${CACHEFIELD[$2]}"
	fi
fi

echo -ne "\e[?25h" # Show cursor.

echo -e "\n\n\n\n\n" # (Temporal).
