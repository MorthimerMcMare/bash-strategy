#!/bin/bash

# "$1" is a pair "$x,$y" of the attacker coordinates.
# "$2" is a pair "$x,$y" of the target coordinates.

if [[ -z "$2" || "$3" ]]; then
	echo "obj_attack(): wrong number of arguments."
	echo "Usage: <int:srcx>,<int:srcy> <int:targx>,<int:targy>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_attack(): game not launched."
	source shutdown.sh error
fi


absdelta() {
	(( $1 - $2 < 0 )) && echo $(( $2 - $1 )) || echo $(( $1 - $2 ))
}


if [[ ! ( -z ${OBJECTS[$1]} || -z ${OBJECTS[$2]} ) && (( ${OBJECTSMOVE[$1]} > 0 )) ]]; then
	OBJ1ATTR="$(. obj_getattr.sh "$1" "attr")"
	OBJ2ATTR="$(. obj_getattr.sh "$2" "attr")"
	BACKFIRERANGE=1
	XYDELTA=1


	#OBJECTSMOVE[$1]=$(( ${OBJECTSMOVE[$1]} - 1 ))

	# Check for attack range modifiers:
	if [[ $OBJ1ATTR == *"atkRange:"* ]]; then

		if [[ $OBJ2ATTR == *"atkRange:"* ]]; then
			BACKFIRERANGE=$(echo "$OBJ2ATTR" | sed "s/.*atkRange:\([[:digit:]]\)\+.*/\1/1")  #"#
		fi

		# Use of non-described variables isn't a goot idea, actually...
		#"$CUR_" varibles is a target position (assigned in "input_targetmode.sh");
		#"$TARGETER_" varibles is an attacker position (assigned in the same file).
		XYDELTA=$(( $(absdelta "$CURX" "$TARGETERX") + $(absdelta "$CURY" "$TARGETERY") ))
	fi

	OBJECTSHP[$2]=$(( ${OBJECTSHP[$2]} - $(. obj_getattr.sh "$1" "atk") ))
	source tile_explode.sh "$2"

	if (( $BACKFIRERANGE >= $XYDELTA )); then
		OBJECTSHP[$1]=$(( ${OBJECTSHP[$1]} - $(. obj_getattr.sh "$2" "batk") ))
		source tile_explode.sh "$1"

		# Attacker object dies:
		(( ${OBJECTSHP[$1]} <= 0 )) && source obj_die.sh "$1" #& ATTACKERDIEPID=$?
	fi

	# Target object dies:
	(( ${OBJECTSHP[$2]} <= 0 )) && source obj_die.sh "$2" #& TARGETDIEPID=$?

	# Async execution causes ambiguous behaviour on associative arrays.
	#wait -f $ATTACKERDIEPID
	#wait -f $TARGETDIEPID
fi
