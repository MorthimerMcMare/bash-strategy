#!/bin/bash

# "$1" is a pair "$x,$y" of the object (and the base) coordinates.

if [[ -z "$1" || ! -z "$2" ]]; then
	echo "obj_capturebase(): wrong number of arguments."
	echo "Usage: <int:objx>,<int:objy>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_capturebase(): game not launched."
	source shutdown.sh error
fi


# Captures base only if:
#  - Object exists and can move, and
#  - A tile has a "freebase" attribute, and
#  - Tile is not this player's base:
[ -z "${OBJECTS[$1]}" ] && return 1

CUROBJECTTEAM=$(. obj_getattr.sh "$1" "team")
if [[ ${TILEATTRS[${FIELD[$1]}]} == *"occupablebase"* && ${FIELD[$1]:$((${#FIELD[$1]} - 1))} != $CUROBJECTTEAM ]]; then
	TILEEXPRESSION=1
else
	TILEEXPRESSION=0
fi

if [[ (( ${OBJECTSMOVE[$1]} > 0 )) && (( $TILEEXPRESSION == 1 )) ]]; then
	CELLY=$(( $(echo "$1" | cut -d"," -f1) + $SCREENMINY ))
	CELLX=$(( $(echo "$1" | cut -d"," -f2) + $SCREENMINX ))

	echo -ne "\e[?25l" # Hides cursor.

	FIELD[$1]="PlayerBase$CUROBJECTTEAM"
	source drawfield.sh "updatecache" "$1"

	CAPSYMBOL="$(. obj_getattr.sh "$1" "symb")"
	#echo -ne "\e[7;${OBJECTSCOLOR[$1]}m$(. obj_getattr.sh "$1" "symb")\e[0m"
	for (( i_capb = 0; i_capb < 10; i_capb++ )); do
		echo -ne "\e[$CELLY;${CELLX}H"
		echo -ne "\e[$(( $i_capb % 2 * 7 ));97m$CAPSYMBOL\e[0m"
		sleep 0.02
	done

	unset OBJECTS[$1]
	unset OBJECTSHP[$1]
	unset OBJECTSMOVE[$1]
	unset OBJECTSCOLOR[$1]

	source drawfield.sh "default" "$1"

	unset CELLX
	unset CELLY

	echo -ne "\e[?25h" # Shows cursor.
	
	return 0
fi

return 1
