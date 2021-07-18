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
	echo "setupTiles(): reading \"$TILESFILE\"..."

	LINE=""
	while read -r LINE || [[ -n $LINE ]]; do
		# Get rid of comments ("//") and empty lines:
		LINE=$(printf "%s\n" "$LINE" | sed -e "s=\/\/.*==g")
		[[ -z "$LINE" ]] && continue

		NAME=$(printf "%s\n" "$LINE" | cut -f1)
		SYMBOL=$(printf "%s\n" "$LINE" | cut -f2)
		COLOR=$(printf "%s\n" "$LINE" | cut -f3)

		if [[ "$COLOR" == "nocolor" ]]; then
			TILES[$NAME]="${SYMBOL}"
		else
			TILES[$NAME]="\\e[${COLOR}m${SYMBOL}\\e[0m"
		fi

		TILEATTRS[$NAME]="$(printf "%s\n" "$LINE" | cut -f4)"
		#printf "Tile: %s\n" "$LINE"
	done < $TILESFILE
	unset LINE

	echo "setupTiles(): done reading \"$TILESFILE\"."
	unset TILESFILE
}

setupObjectClasses() {
	OBJFILE=$1

	# Read objects data:
	echo "setupObjectClasses(): reading \"$OBJFILE\"..."

	LINE=""
	CURNAME=""
	while read -r LINE || [[ -n $LINE ]]; do
		# Get rid of comments ("//") and empty lines:
		LINE=$(printf "%s\n" "$LINE" | sed -e "s=\/\/.*==g")
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

	echo "setupObjectClasses(): done reading \"$OBJFILE\"."
	unset OBJFILE
}

setupField() {
	MAPFILE="$1"

	echo "setupField(): reading \"$MAPFILE\"..."
	CURMAPSECTION=""
	LINE=""
	while read -r LINE || [[ -n $LINE ]]; do
		# Get rid of comments ("//") and empty lines:
		LINE=$(printf "%s\n" "$LINE" | sed -e "s=\/\/.*==g")
		[[ -z "$LINE" ]] && continue

		# Get the current map section and cnvert it to the lowercase:
		[[ "${LINE:0:1}" == '[' ]] && CURMAPSECTION=$(echo $LINE | sed "s/\[\(.\{2,20\}\)\]/\L\1/1") && continue
		#"# Required by the MC colorer.
		#echo \"$LINE\" / \"$CURMAPSECTION\"

		case $CURMAPSECTION in
			"tiles")
				setupTiles $LINE
				;;
			"aliases")
				FIELDALIASES["$(echo $LINE | cut -d" " -f2)"]="$(echo $LINE | cut -d" " -f1)"
				;;
			"players")
				CURPLAYER=$(echo $LINE | cut -d" " -f1)
				# Black and white aren't presented here.
				if [[ "$CURPLAYER" < "1" || "$CURPLAYER" > "6" ]]; then
					CURPLAYER=$(( $(echo $RANDOM) % 7 + 1 ))
				fi
				# Randomly changes the player color intensity:
				#CURPLAYER=$(( $CURPLAYER + $(echo $RANDOM) % 2 * 60 ))
				PLAYERS[$CURPLAYER]="$CURPLAYER"
				PLAYERSINFO[$CURPLAYER]=$(echo $LINE | cut -d" " -f2)

				CURPLAYERCOLOR=$(( $CURPLAYER + 30 + 60 * ( $(echo $RANDOM) % 2 ) ))

				TILES[PlayerBase$CURPLAYER]="\\e[${CURPLAYERCOLOR}m${TILES[PlayerBase]}\\e[0m"
				TILEATTRS[PlayerBase$CURPLAYER]="${TILEATTRS[PlayerBase]}"
				FIELDALIASES[$CURPLAYER]="PlayerBase$CURPLAYER"

				echo "setupField(): player $CURPLAYER added."
				;;
			"map")
				(( $FIELDMAXX == 0 )) && FIELDMAXX=${#LINE}
				if (( $FIELDMAXX != ${#LINE} )); then
					echo "setupField(): warning: different field X ($FIELDMAXX known, ${#LINE} get)."
					sleep 0.5
				fi

				for (( x = 0; x < FIELDMAXX; x++ )); do
					CURCELL=${LINE:$x:1}
					FIELD[$FIELDMAXY,$x]=${FIELDALIASES[$CURCELL]}
				done

				FIELDMAXY=$(( $FIELDMAXY + 1 ))
				;;
			*)
				echo "setupField(): warinig: unknown section name \"$CURMAPSECTION\"."
				sleep 0.5
				;;
		esac

		: 'case $(echo $LINE | cut -d" " -f1) in
			"tiles")
				setupTiles $(echo $LINE | cut -d" " -f2)
				;;
			"set")
				FIELDALIASES["$(echo $LINE | cut -d" " -f3)"]="$(echo $LINE | cut -d" " -f2)"
				;;
			"addPlayerBase")
				CURPLAYER=$(echo $LINE | cut -d" " -f2)
				# Black and white aren`t presented here.
				if [[ "$CURPLAYER" < "1" || "$CURPLAYER" > "6" ]]; then
					CURPLAYER=$(( $(echo $RANDOM) % 7 + 1 ))
				fi
				# Randomly changes the player color intensity:
				#CURPLAYER=$(( $CURPLAYER + $(echo $RANDOM) % 2 * 60 ))
				PLAYERS[$CURPLAYER]="$CURPLAYER"
				PLAYERCOLOR=$(( $CURPLAYER + 30 + 60 * ( $(echo $RANDOM) % 2 ) ))

				echo "setupField(): player $CURPLAYER added."

				TILES[PlayerBase$CURPLAYER]="\\e[${PLAYERCOLOR}m${TILES[PlayerBase]}\\e[0m"
				TILEATTRS[PlayerBase$CURPLAYER]="${TILEATTRS[PlayerBase]}"

				FIELDALIASES[$CURPLAYER]="PlayerBase$CURPLAYER"
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
		'
	done < $MAPFILE
	unset LINE

	echo "setupField(): done reading \"$MAPFILE\"."
	unset MAPFILE
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
# (It seems like this arrays mustn't be associative?)
declare -g -A PLAYERS && declare -g -A PLAYERSINFO


setupField "$1"
setupObjectClasses "$2"

clear

source obj_create.sh "Light tank" "1" "2,2"
source obj_create.sh "Heavy tank" "2" "3,3"
source obj_create.sh "BTR" "2" "3,7"
source obj_create.sh "Light tank" "2" "4,7"
source obj_create.sh "Trike" "1" "2,4"

source drawfield.sh "(from setupgame.sh)"

# Ten times blows up the second (internally "1"st) column:
#for (( ix = 0; ix < 10; ix++ )); do for (( jx = 0; jx < 8; jx++ )); do source tile_explode.sh "$jx,1"; done; done


source obj_move.sh "4,7" "5,7" && sleep 0.4
source obj_move.sh "2,2" "2,3" && sleep 0.4
source obj_attack.sh "2,3" "3,3"  && sleep 0.4
source obj_move.sh "2,3" "2,2"  && sleep 0.4
source obj_move.sh "3,3" "2,3"  && sleep 0.4
source obj_attack.sh "2,2" "2,3"  && sleep 0.4
source obj_attack.sh "2,2" "2,3"  && sleep 0.4
: '
source obj_move.sh "2,4" "2,5"  && sleep 0.4
source obj_move.sh "2,5" "2,6"  && sleep 0.4
source obj_move.sh "2,6" "2,5"  && sleep 0.4
source obj_capturebase.sh "2,5"  && sleep 0.4
source obj_move.sh "3,7" "2,7"  && sleep 0.4
source obj_move.sh "2,7" "2,6"  && sleep 0.4
source obj_move.sh "2,6" "2,5"  && sleep 0.4
source obj_capturebase.sh "2,5"  && sleep 0.4
: ' #'

echo -ne "\e[?25h" # Shows cursor.

