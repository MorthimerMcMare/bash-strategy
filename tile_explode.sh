#!/bin/bash

# "$1" is a pair "$x,$y" of the tile coordinates.

if [[ -z "$1" || ! -z "$2" ]]; then
	echo "tile_explode(): wrong number of arguments."
	echo "Usage: <int:tilex>,<int:tiley>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "tile_explode(): game not launched."
	source shutdown.sh error
fi

TILEATTR=${TILEATTRS[${FIELD[$1]}]}

if [[ $TILEATTR == *"explosion:"* ]]; then

	for i in $(echo "$TILEATTR"); do
		if [[ "$i" == "explosion:"* ]]; then
			CHANCE=$(echo "$i" | cut -d":" -f2)
			NEWTILE=$(echo "$i" | cut -d":" -f3)

			if (( $RANDOM % 100 < $CHANCE )); then
				FIELD[$1]="$NEWTILE"
				source drawfield.sh "updatecache" "$1"
				source drawfield.sh "default" "$1"

				break
			fi

		fi
	done

fi