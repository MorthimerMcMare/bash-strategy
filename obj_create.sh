#!/bin/bash

# "$1" is a name from objects data file, spaces are permitted.
# "$2" is a belonging to a particular team (1..6).
# "$3" must be a "$x,$y" pair.

if [[ -z "$3" || ! -z "$4" ]]; then
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
[[ $(echo "${CLASSTEAMS[$1]}" | grep -c "$2") == "1" ]] && TEAMSEXPRESSION=1 || TEAMSEXPRESSION=0

if [[ -z ${OBJECTS[$3]} && (( $TEAMSEXPRESSION == 1 )) && $CELlX < $FIELDMAXX && $CELLY < $FIELDMAXY ]]; then
	OBJECTS[$3]="$1"
	OBJECTSHP[$3]=$(. obj_getattr.sh "$3" "maxhp")
	OBJECTSMOVE[$3]=$(. obj_getattr.sh "$3" "range")
	OBJECTSCOLOR[$3]=$(( $2 + 30 + 60 * ( $(echo $RANDOM) % 2 ) ))

	# There's cannot be reality where single object draws before field. Theoretically...
	#source drawfield.sh "default" "$3"
fi
