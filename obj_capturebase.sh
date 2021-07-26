#!/bin/bash

# "$1" is a pair "$x,$y" of the object (and the base) coordinates.

if [[ -z "$1" || "$2" ]]; then
	echo "obj_capturebase(): wrong number of arguments."
	echo "Usage: <int:objx>,<int:objy>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_capturebase(): game not launched."
	source shutdown.sh error
fi


# Captures base only if:
#  - Object exists, belongs to team with current turn and can move, and
#  - A tile has a "occupablebase" attribute, and
#  - Tile is not this player's base:
[ -z "${OBJECTS[$1]}" ] && return 1

CUROBJECTTEAM=$(. obj_getattr.sh "$1" "team")
if [[ $CUROBJECTTEAM -eq $TURN && ${TILEATTRS[${FIELD[$1]}]} == *"occupablebase"* && ${FIELD[$1]: -1} != $CUROBJECTTEAM ]]; then
	TILEEXPRESSION=1
else
	TILEEXPRESSION=0
fi

if [[ (( ${OBJECTSMOVE[$1]} > 0 )) && (( $TILEEXPRESSION == 1 )) ]]; then
	echo -ne "\e[?25l" # Hides cursor.

	FIELD[$1]="PlayerBase$CUROBJECTTEAM"
	source drawfield.sh "updatecache" "$1"

	source base_updatequickaccess.sh "$1" "$TURN"

	# For demo files.
	echo -ne "\e[$(( ${1%,*} + $SCREENMINY ));$(( ${1#*,} + $SCREENMINX ))H"

	CAPSYMBOL="$(. obj_getattr.sh $1 symb)"
	for (( i_capb = 0; i_capb < 10; i_capb++ )); do
		echo -ne "\e[$(( $i_capb % 2 * 7 ));97m$CAPSYMBOL\e[0m\e[1D"
		sleep 0.02
	done

	unset OBJECTS[$1]
	unset OBJECTSHP[$1]
	unset OBJECTSMOVE[$1]
	unset OBJECTSCOLOR[$1]

	source drawfield.sh "default" "$1"

	return 0
fi

return 1
