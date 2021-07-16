#!/bin/bash

setupTiles() {
	# Tiles data variable:
	declare -g -A TILES && declare -g -A TILEATTRS

	if [[ ! -f $1 ]]; then
		echo "Warning: cannot find tiles file \"$1\", using \"tileset1.tls\"."
		[[ ! -f "tileset1.tls" ]] && echo "Error: cannot find default tileset file \"tileset1.tls\"." && . shutdown.sh error
		TILESFILE="tileset1.tls"
	else
		TILESFILE=$1
	fi

	# Read tiles:
	echo -n " \\_ Reading \"$TILESFILE\"... "

	LINE=""
	while read -r LINE || [[ -n $LINE ]]; do
		# Get rid of comments ("//") and empty lines:
		LINE=$(printf "%s\n" "$LINE" | sed -e "s=\/\/.\+==g")
		[[ -z "$LINE" ]] && continue

		SYMBOL=$(printf "%s\n" "$LINE" | cut -f2)
		COLOR=$(printf "%s\n" "$LINE" | cut -f3)
		ATTR=$(printf "%s\n" "$LINE" | cut -f4)
		TILES[$(printf "%s\n" "$LINE" | cut -f1)]="\\e[${COLOR}m${SYMBOL}\\e[0m"
		TILEATTRS[$(printf "%s\n" "$LINE" | cut -f1)]="$ATTR"
		#printf "Tile: %s\n" "$LINE"
	done < $TILESFILE
	unset LINE

	unset TILESFILE
	echo Done.
}

setupObjectClasses() {
	OBJFILE=$1

	# Read objects data:
	echo -n "Reading \"$OBJFILE\"... "

	LINE=""
	CURNAME=""
	while read -r LINE || [[ -n $LINE ]]; do
		# Get rid of comments ("//") and empty lines:
		LINE=$(printf "%s\n" "$LINE" | sed -e "s=\/\/.\+==g")
		[ -z "$LINE" ] && continue

		if [ -z "$CURCLASS" ]; then
			CURCLASS=$(echo "$LINE" | cut -d":" -f1)
			#"# For the MC colorer.

			if [ ! -z "$CURCLASS" ]; then
				# Write team info:
				CLASSTEAMS[$CURCLASS]="$(echo "$LINE" | sed -e "s/.\+:\s\(.\+\)/\1/g" -e "s/\s/\t/g")"
				#"# For the MC colorer...
				#echo "${CLASSTEAMS[$CURCLASS]}"
			fi
		else
			CLASSPROPS[$CURCLASS]="\
$(echo "$LINE" | cut -d" " $CLASS_SYMBOL)\
	$(echo "$LINE" | cut -d" " $CLASS_MAXHP)\
	$(echo "$LINE" | cut -d" " $CLASS_ATK)\
	$(echo "$LINE" | cut -d" " $CLASS_BATK)\
	$(echo "$LINE" | cut -d" " $CLASS_COST)\
	$(echo "$LINE" | cut -d" " $CLASS_RANGE)"

			CLASSATTRS[$CURCLASS]="$(echo "$LINE" | cut $CLASS_ATTR)"

			#echo "$CURCLASS: ${CLASSPROPS[$CURCLASS]}"
			CURCLASS=""
		fi

		#printf "Line: %s\n" "$LINE"
	done < $OBJFILE
	unset LINE

	unset OBJFILE
	echo Done.
}

setupField() {
	MAPFILE="$1"

	echo "Reading \"$MAPFILE\"... "
	LINE=""
	while read -r LINE || [[ -n $LINE ]]; do
		# Get rid of comments ("//") and empty lines:
		LINE=$(printf "%s\n" "$LINE" | sed -e "s=\/\/.\+==g")
		[[ -z "$LINE" ]] && continue

		case $(echo $LINE | cut -d" " -f1) in
			"tiles")
				setupTiles $(echo $LINE | cut -d" " -f2)
				;;
			"set")
				FIELDALIASES["$(echo $LINE | cut -d" " -f3)"]="$(echo $LINE | cut -d" " -f2)"
				;;
			"addPlayerBase")
				CURPLAYER=$(echo $LINE | cut -d" " -f2)
				# Black and white aren't presented here.
				if [[ "$CURPLAYER" < "1" || "$CURPLAYER" > "6" ]]; then
					CURPLAYER=$(( $(echo $RANDOM) % 7 + 1 ))
				fi
				# Randomly changes the player color intensity:
				#CURPLAYER=$(( $CURPLAYER + $(echo $RANDOM) % 2 * 60 ))
				PLAYERS[$CURPLAYER]="$CURPLAYER"
				PLAYERCOLOR=$(( $CURPLAYER + 30 + 60 * ( $(echo $RANDOM) % 2 ) ))

				echo " \\_ Player $CURPLAYER added."

				TILES[BasePlayer$CURPLAYER]="\\e[${PLAYERCOLOR}m${SYMBOL}\\e[0m"
				TILEATTRS[BasePlayer$CURPLAYER]=TILEATTRS[FreeBase]

				FIELDALIASES[$CURPLAYER]=BasePlayer$CURPLAYER
				;;
			"addLine")
				CURMAPLINE=$(echo $LINE | cut -d" " -f2)
				(( FIELDMAXX == 0 )) && FIELDMAXX=${#CURMAPLINE}

				for (( x = 0; x < FIELDMAXX; x++ )); do
					CURCELL=${CURMAPLINE:$x:1}
					FIELD[$FIELDMAXY,$x]=${FIELDALIASES[$CURCELL]}
				done

				FIELDMAXY=$(( $FIELDMAXY + 1 ))
				;;
			*)
				;;
		esac
	done < $MAPFILE
	unset LINE

	unset MAPFILE
	echo "Done."
}


if [[ -z "$2" || ! -z "$3" ]]; then
	echo "setupField(): wrong number of arguments."
	echo "Usage: <string:map_filename> <string:objdata_filename>."
	source shutdown.sh error
elif [[ ! -f "$1" ]]; then
	echo "setupField(): cannot find map file \"$1\"." 
	source shutdown.sh error
elif [[ ! -f "$2" ]]; then
	echo "setupField(): cannot find objects data file \"$2\"."
	source shutdown.sh error
fi


# "Utils" (for the "cut" command):
CLASS_SYMBOL="-f1"
CLASS_MAXHP="-f2"
CLASS_ATK="-f3"
CLASS_BATK="-f4"
CLASS_COST="-f5"
CLASS_RANGE="-f6"
CLASS_ATTR="-f7"

FIELDMAXX=0
FIELDMAXY=0
SCREENMINX=10
SCREENMINY=5

# Clear all previous potencially set variables:
source clearvariables.sh

# Field variables ([x/y] map layer and quick aliases):
declare -g -A FIELD && declare -g -A FIELDALIASES

# Class "static" variables:
declare -g -A CLASSPROPS && declare -g -A CLASSTEAMS && declare -g -A CLASSATTRS

# Object variables ([x/y] classes, [x/y] their HP and [x/y] their colors):
#"$OBJECTSMOVE" is a free turns left for the object.
#"$OBJECTSCOLOR" is also the object team (as "($OBJECTCOLORS % 10)").
declare -g -A OBJECTS && declare -g -A OBJECTSHP && declare -g -A OBJECTSMOVE && declare -g -A OBJECTSCOLOR

# Players info (player color and a money value it has):
declare -g -A PLAYERS && declare -g -A PLAYERSINFO


setupField $1
setupObjectClasses $2

#source obj_create.sh "Light tank" "1" "2,2"
#source obj_create.sh "Heavy tank" "2" "6,3"
#source obj_create.sh "BTR" "2" "3,7"
#source obj_create.sh "Light tank" "2" "4,7"
#source obj_create.sh "Trike" "1" "2,4"

source drawfield.sh ""
