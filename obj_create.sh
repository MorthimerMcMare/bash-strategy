#!/bin/bash

# "$1" is a name from objects data file, spaces are permitted.
# "$2" is a belonging to a particular player (1..6).
# "$3" must be a "$x,$y" pair.

if [[ -z "$3" || "$4" ]]; then
	echo "obj_create(): wrong number of arguments."
	echo "Usage: <string:obj_type> <int_from1to6:obj_team> <int:x>,<int:y>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_create(): game not launched."
	source shutdown.sh error
fi

CELLY=${2%,*}
CELLX=${2#*,}

# Is spawnee object belongs to the team specified in the second argument:
[[ "${TEAMCLASSES[$2]}" == *"$1"* ]] && TEAMSEXPRESSION=1 || TEAMSEXPRESSION=0

if [[ -z ${OBJECTS[$3]} && (( $TEAMSEXPRESSION == 1 )) && $CELLX -lt $FIELDMAXX && $CELLY -lt $FIELDMAXY ]]; then
	OBJECTS[$3]="$1"
	OBJECTSHP[$3]=$(. obj_getattr.sh "$3" "maxhp")
	#OBJECTSMOVE[$3]=$(. obj_getattr.sh "$3" "range")
	OBJECTSMOVE[$3]=0
	PLAYERCOLOR=$(( ${PLAYERS[$2]} % 10 + 30 ))
	OBJECTSCOLOR[$3]=$(( $PLAYERCOLOR + 60 * ( $(echo $RANDOM) % 2 ) ))

	# There's cannot be reality where single object draws before field. 
	#Theoretically...
	source drawfield.sh "default" "$3"
fi
