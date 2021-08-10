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

# "$1" is a player which bases must be recalculated.
recalculate_base_indices() {
	declare -a TEMPBASES=( )
	TEMPINDEX=0

#####for i_rbi in ${!PLAYERBASES[*]}; do echo "PLAYERBASES. $i_rbi: ${PLAYERBASES[$i_rbi]}"; done
#####echo "\${PLAYERBASES[$1:count]}: ${PLAYERBASES[$1:count]}"

	# Save list of all $1's available bases (and quite more):
	for (( i_rbi = 0; i_rbi < ${PLAYERBASES[$1:count]} + 2; i_rbi++ )); do
		if [ "${PLAYERBASES[$1:$i_rbi]}" ]; then
			TEMPBASES[$TEMPINDEX]="${PLAYERBASES[$1:$i_rbi]}"
#####echo ${PLAYERBASES[$1:$i_rbi]}
			: $(( TEMPINDEX++ ))
		fi
	done

#####for i_rbi in ${!TEMPBASES[*]}; do echo "bfr. $i_rbi: ${TEMPBASES[$i_rbi]}"; done

	# Rewrite indices:
	MAXTEMPINDEX=$TEMPINDEX

	for (( i_rbi = 0; i_rbi < ${PLAYERBASES[$1:count]} + 2; i_rbi++ )); do
		if (( $i_rbi < $MAXTEMPINDEX )); then
			PLAYERBASES[$1:$i_rbi]="${TEMPBASES[$i_rbi]}"
		else
			unset PLAYERBASES[$1:$i_rbi]
		fi
	done

	# Finalize:
	PLAYERBASES[$1:count]=$MAXTEMPINDEX

#####echo "base_updatequickaccess(): new player $1 bases count: $MAXTEMPINDEX." && sleep 0.5
#####for i_rbi in ${!PLAYERBASES[*]}; do echo "end PLAYERBASES. $i_rbi: ${PLAYERBASES[$i_rbi]}"; done

	unset MAXTEMPINDEX
	unset TEMPINDEX
	unset TEMPBASES
}


if [[ "${FIELD[$1]}" == *"Base"* && $2 -lt $MAXPLAYERS ]]; then
	# Remove this base from any other player:
	for i_bupd in ${!PLAYERBASES[*]}; do
		if [[ "$i_bupd" != *"count"* && "${PLAYERBASES[$i_bupd]}" == "$1" ]]; then
			unset PLAYERBASES[$i_bupd]
			recalculate_base_indices "${i_bupd%:*}"

			break
		fi
	done


	# Add captured base to quick access:

	# Assign base to first empty index:
	#for (( NEXTBASEINDEX=1; NEXTBASEINDEX < ${PLAYERBASES[$2:count]}; NEXTBASEINDEX++ )) do
	#	[ -z "${PLAYERBASES[$2:$NEXTBASEINDEX]}" ] && PLAYERBASES[$2:$NEXTBASEINDEX]="$1" && break
	#done

	PLAYERBASES[$2:$(( ${PLAYERBASES[$2:count]} + 1 ))]="$1"

	recalculate_base_indices "$2"

	PLAYERS[$2:curbase]=$NEXTBASEINDEX

	#echo "pl\"$2\" set base to index=$(( ${PLAYERBASES[$2:count]} + 1 )) from max=${PLAYERBASES[$2:count]}" && sleep 0.5
fi

