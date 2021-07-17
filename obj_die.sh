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


CELLY=$(( $(echo "$1" | cut -d"," -f1) + $SCREENMINY ))
CELLX=$(( $(echo "$1" | cut -d"," -f2) + $SCREENMINX ))

unset OBJECTS[$1]
unset OBJECTSHP[$1]
unset OBJECTSMOVE[$1]
unset OBJECTSCOLOR[$1]

# An explosion:
EXPLCOLOR=31
EXPLCOLORATTR=$(( 2 ** ( $RANDOM % 3 + 1 ) - 1 )) # Bold, italic or reversive...
case $(( $RANDOM % 4 )) in
	"0") EXPLCOLOR=91 ;;
	"1") EXPLCOLOR=93 ;;
	"2") EXPLCOLOR=97 ;;
	*) ;;
esac
echo -ne "\e[$CELLY;${CELLX}H\e[${EXPLCOLORATTR};${EXPLCOLOR}m*\e[0m"
sleep 0.15
#read -s -n1

source drawfield.sh "default" "$1"


unset CELLX
unset CELLY
