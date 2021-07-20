#!/bin/bash

# "$1" is a pair "$x,$y" of the victim coordinates.

if [[ -z "$1" || ! -z "$2" ]]; then
	echo "obj_die(): wrong number of arguments."
	echo "Usage: <int:objx>,<int:objy>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "obj_die(): game not launched."
	source shutdown.sh error
fi


# Screen x/y:
SCRY=$(( ${1%,*} + $SCREENMINY ))
SCRX=$(( ${1#*,} + $SCREENMINX ))

unset OBJECTS[$1]
unset OBJECTSHP[$1]
unset OBJECTSMOVE[$1]
unset OBJECTSCOLOR[$1]

# An explosion (decoration):
explode() {
	declare -a EXPLCOLOR=( 97 93 91 31 )

	for (( explstate = 0; explstate < 4; explstate++ )); do
		echo -ne "\e[$SCRY;${SCRX}H\e[${EXPLCOLOR[$explstate]}m*\e[0m"

		SLEEPTIME=$((1 + $1))
		(( $SLEEPTIME < 10 )) && SLEEPTIME="0$SLEEPTIME"
		sleep "0.$SLEEPTIME"

		if (( $explstate >= 2 )); then
			SLEEPTIME=$((4 + $1))
			(( $SLEEPTIME < 10 )) && SLEEPTIME="0$SLEEPTIME"
			sleep "0.$SLEEPTIME"
		fi
	done
}

explode $(( $RANDOM % 7 ))

source tile_explode.sh "$1" "do_not_drawfield"
source drawfield.sh "default" "$1"


unset SCRX
unset SCRY

#return $!
