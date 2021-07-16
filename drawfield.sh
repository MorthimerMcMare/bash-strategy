#!/bin/bash

# Updating field cache:
if [[ "$1" == "update" || ( -z ${CACHEFIELD[exists]+x} ) ]]; then
	COORDS="$2"

	# Force full update if there's no field cache:
	[ -z ${CACHEFIELD+x} ] && declare -g -A CACHEFIELD=( [exists]="yes" ) && COORDS=""
	
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
fi


# Drawing a map itself:
SCREENMINX=10
SCREENMINY=5

clear # Temporal.
#echo -ne "\e[H"

for (( y = 0; y < $FIELDMAXY; y++ )); do
	echo -ne "\e[$((y + SCREENMINY));${SCREENMINX}H"

	for (( x = 0; x < $FIELDMAXX; x++ )); do
		if [[ "$1" == "objectshp" && ! -z ${OBJECTS[$y,$x]} ]]; then
			echo -ne "\e[${OBJECTCOLORS[$y,$x]}m${OBJECTSHP[$y,$x]}\e[0m"
		elif [[ "$1" != "noobjects" && ! -z ${OBJECTS[$y,$x]} ]]; then
			echo -ne "\e[${OBJECTCOLORS[$y,$x]}m$(. obj_getattr.sh $y,$x symbol)\e[0m"
		else
			echo -n "${CACHEFIELD[$y,$x]}"
		fi
	done
done

echo -e "\n\n\n"
