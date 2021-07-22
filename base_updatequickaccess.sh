#!/bin/bash

# "$1" is a pair "$x,$y" of the base coordinates.
# "$2" is a player.

if [[ -z "$2" || "$3" ]]; then
	echo "base_updatequickaccess(): wrong number of arguments."
	echo "Usage: <int:x>,<int:y> <int:player>."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "base_updatequickaccess(): game not launched."
	source shutdown.sh error
fi


if [[ "${FIELD[$1]}" == *"Base"* && $2 -lt $MAXPLAYERS ]]; then
	# Remove this base from any other player:
	for i_bupd in ${!PLAYERBASES[*]}; do
		if [[ "$i_bupd" != *"count"* && "${PLAYERBASES[$i_bupd]}" == "$1" ]]; then
			CURPLAYER=${i_bupd%:*}
			PLAYERBASES[$CURPLAYER:count]=$(( ${PLAYERBASES[$CURPLAYER:count]} - 1 ))
			unset PLAYERBASES[$i_bupd]
		fi
	done

	# Add captured base to quick access:
	NEXTBASEINDEX=$(( ${PLAYERBASES[$2:count]} + 1 ))
	PLAYERBASES[$2:$NEXTBASEINDEX]="$1"
	PLAYERBASES[$2:count]=$NEXTBASEINDEX
	#PLAYERBASES[$2:count]=$(( ${PLAYERBASES[$2:count]} + 1 ))
	PLAYERS[$2:curbase]=$NEXTBASEINDEX
	

	#echo "pl\"$2\" to \"${PLAYERBASES[$2:$NEXTBASEINDEX]}\"/\"${PLAYERBASES[$2:count]}\""
fi

