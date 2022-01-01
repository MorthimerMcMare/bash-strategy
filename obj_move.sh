#!/bin/bash

# "$1" is a pair "$x,$y" of the source coordinates.
# "$2" is a pair "$x,$y" of the destination coordinates.

if [[ -z "$2" || "$3" ]]; then
	echo "obj_move(): wrong number of arguments."
	echo "Usage: <int:srcx>,<int:srcy> <int:destx>,<int:desty>."
	source shutdown.sh error
elif [[ -z "${GAME_BASH_STRATEGY+x}" ]]; then
	echo "obj_move(): game not launched."
	source shutdown.sh error
fi


[[ ${2#*,} < $FIELDMAXX && ${2%,*} < $FIELDMAXY ]] && INBOUNDSEXPR="true" || INBOUNDSEXPR=""

if [[ -z ${OBJECTS[$2]} && "$INBOUNDSEXPR" && (( ${OBJECTSMOVE[$1]} > 0 )) ]]; then
	TILEATTR="${TILEATTRS[${FIELD[$2]}]}"
	OBJATTR="$(. obj_getattr.sh $1 attr)"

	PASSIBILITY=1

	# If a tile has a pass-modifier, we must check all of the attributes:
	if [[ $TILEATTR == *"passible"* ]]; then
		for i in $(echo "$TILEATTR"); do
			[ $i == "impassible" ] && PASSIBILITY=0

			# Check for "[im]passible" attribute prefix isn't necessary, because
			#"$i" has no excess symbols at the beginnig of the string.
			if [[ $i == "passible:"* && ( "$OBJATTR" == *"passattr:${i#*:}"* ) ]]; then
				PASSIBILITY=1
			fi
		done
	fi

	if (( $PASSIBILITY == 1 )); then
		OBJECTS[$2]=${OBJECTS[$1]}
		OBJECTSHP[$2]=${OBJECTSHP[$1]}
		OBJECTSMOVE[$2]=$(( ${OBJECTSMOVE[$1]} - 1 ))
		#OBJECTSMOVE[$2]=${OBJECTSMOVE[$1]} # (4debug).
		OBJECTSCOLOR[$2]=${OBJECTSCOLOR[$1]}

		unset OBJECTS[$1]
		unset OBJECTSHP[$1]
		unset OBJECTSMOVE[$1]
		unset OBJECTSCOLOR[$1]

		source drawfield.sh "default" "$2"
		source drawfield.sh "default" "$1"

		return 0
	fi
#else; echo -e "NOT MOVED (src:$1; dst:$2)"
fi

return 1
