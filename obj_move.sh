#!/bin/bash

# "$1" is a pair "$x,$y" of the source coordinates.
# "$2" is a pair "$x,$y" of the destination coordinates.

if [[ -z "$2" || ! -z "$3" ]]; then
	echo "obj_move(): wrong number of arguments."
	echo "Usage: <int:srcx>,<int:srcy> <int:destx>,<int:desty>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_move(): game not launched."
	source shutdown.sh error
fi

#SRCY=$(echo "$1" | cut -d"," -f1)
#SRCX=$(echo "$1" | cut -d"," -f2)
DSTY=$(echo "$2" | cut -d"," -f1)
DSTX=$(echo "$2" | cut -d"," -f2)

if [[ -z ${OBJECTS[$2]} && $DSTX < $FIELDMAXX && $DSTY < $FIELDMAXY ]]; then
	TILEATTR=${TILEATTRS[${FIELD[$2]}]}
	OBJATTR="$(. obj_getattr.sh "$1" "attr")"
	PASSIBILITY=1

	# If a tile has a pass-modifier, we must check all of the attributes:
	if [[ $TILEATTR == *"passible"* ]]; then
		for i in $(echo "$TILEATTR"); do
			[[ $i == "impassible" ]] && PASSIBILITY=0

			if [[ $i == "impassible:"* && ( "$OBJATTR" == *"passattr:$(echo \"$i\" | cut -d":" -f2 )"* ) ]]; then
				PASSIBILITY=1
			fi
		done
	fi

	if (( $PASSIBILITY == 1 )); then
		OBJECTS[$2]=${OBJECTS[$1]}
		OBJECTSHP[$2]=${OBJECTSHP[$1]}
		OBJECTSMOVE[$2]=${OBJECTSMOVE[$1]}
		OBJECTSCOLOR[$2]=${OBJECTSCOLOR[$1]}

		unset OBJECTS[$1]
		unset OBJECTSHP[$1]
		unset OBJECTSMOVE[$1]
		unset OBJECTSCOLOR[$1]

		source drawfield.sh "default" "$1"
		source drawfield.sh "default" "$2"
	fi
fi
