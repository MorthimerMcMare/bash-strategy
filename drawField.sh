#!/bin/bash

# There's must be four variants of redrawing.
declare -g CACHEFIELD=""
#declare -g -A CACHEFIELD

# Updating field cache:
if [[ "$1" == "upd" ]]; then
	for (( y = 0; y < $FIELDMAXY; y++ )); do
		for (( x = 0; x < $FIELDMAXX; x++ )); do
			CACHEFIELD=$CACHEFIELD$(echo -ne ${TILES[${FIELD[$y,$x]}]})
		done
		CACHEFIELD=$CACHEFIELD"\n"
	done
fi

echo -e $CACHEFIELD


# Objects:
if [[ "$1" == "objectshp" ]]; then
	echo "Objects health"
elif [[ "$1" != "noobjects" ]]; then
	echo "All objects"
fi

