#!/bin/bash

# "$1" is a map file to load.
# "$2" is a objects file to load.

if [[ -z "$2" || "$3" ]]; then
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
		LINE=${LINE%%//*}
		[ -z "$LINE" ] && continue

		NAME=$(printf "%s\n" "$LINE" | cut -f1)
		SYMBOL=$(printf "%s\n" "$LINE" | cut -f2)
		COLOR=$(printf "%s\n" "$LINE" | cut -f3)

		if [[ "$COLOR" == "nocolor" ]]; then
			TILES[$NAME]="${SYMBOL}"
		else
			TILES[$NAME]="\\e[${COLOR}m${SYMBOL}\\e[0m"
		fi

		# Parse attributes only in there's more than three tabs in the line
		#("if ( len(LINE) - len(LINE_without_tabs) + 1 > 3 )  {...}"):
		TEMPLINE="${LINE//	}"
		if (( ${#LINE} - ${#TEMPLINE} + 1 > 3 )); then
			# Get all after the last tab character:
			TILEATTRS[$NAME]="${LINE##*	}"
		else
			TILEATTRS[$NAME]=""
		fi

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
		LINE=${LINE%%//*}
		[ -z "$LINE" ] && continue

		if [ -z "$CURCLASS" ]; then
			CURCLASS=${LINE%:*}

			# Write team info:
			[ "$CURCLASS" ] && {
				# Replace all tab occurences to spaces:
				CURCLASS=${CURCLASS//	/ }

				for i_setobj in $(echo "${LINE#*:}"); do
					# Add "$CURCLASS" if "$TEAMCLASSES[$i]" does not exist and 
					#"$TEAMCLASSES[$i]\t$CURCLASS" otherwise:
					TEAMCLASSES[$i_setobj]="${TEAMCLASSES[$i_setobj]-}${TEAMCLASSES[$i_setobj]+	}$CURCLASS"

					[ -z "${PLAYERS[$i_setobj:classesamount]}" ] && PLAYERS[$i_setobj:classesamount]=0
					: $(( PLAYERS[$i_setobj:classesamount]++ ))
				done
			}

			#echo "$CURCLASS: \"${TEAMCLASSES[1]}\",\"${TEAMCLASSES[2]}\""
		else
			CLASSPROPS[$CURCLASS:symb]="$(echo "$LINE" | cut -d" " $CLASS_SYMBOL)"
			CLASSPROPS[$CURCLASS:symb]="${CLASSPROPS[$CURCLASS:symb]:0:1}"
			CLASSPROPS[$CURCLASS:maxhp]="$(echo "$LINE" | cut -d" " $CLASS_MAXHP)"
			CLASSPROPS[$CURCLASS:atk]="$(echo "$LINE" | cut -d" " $CLASS_ATK)"
			CLASSPROPS[$CURCLASS:batk]="$(echo "$LINE" | cut -d" " $CLASS_BATK)"
			CLASSPROPS[$CURCLASS:cost]="$(echo "$LINE" | cut -d" " $CLASS_COST)"
			CLASSPROPS[$CURCLASS:range]="$(echo "$LINE" | cut -d" " $CLASS_RANGE)"

			# Class attributes are also separated by space, so with current 
			#file structure variant I cannot use here bash substrings.
			CLASSATTRS[$CURCLASS]="$(echo "$LINE" | cut -d" " $CLASS_ATTR)"

			#echo "$CURCLASS: ${CLASSPROPS[$CURCLASS:atk]}"
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
		LINE=${LINE%%//*}
		[ -z "$LINE" ] && continue

		# Get the current map section and cnvert it to the lowercase:
		[[ "${LINE:0:1}" == '[' && ${LINE: -1} == ']' ]] && declare -l CURMAPSECTION="${LINE:1: -1}" && continue
		#echo \"$LINE\" / \"$CURMAPSECTION\"

		case $CURMAPSECTION in
			"tiles")
				setupTiles $LINE
				;;
			"aliases")
				FIELDALIASES["${LINE#* }"]="${LINE% *}"
				;;
			"players")
				CURPLAYER=${LINE% *}
				# Black and white aren't presented here.
				if [[ "$CURPLAYER" < "1" || "$CURPLAYER" > "6" ]]; then
					CURPLAYER=$(( $(echo $RANDOM) % 7 + 1 ))
				fi

				# Randomly changes the player color intensity:
				#CURPLAYER=$(( $CURPLAYER + $(echo $RANDOM) % 2 * 60 ))
				CURPLAYERCOLOR=$(( $CURPLAYER + 30 + 60 * ( $(echo $RANDOM) % 2 ) ))
				PLAYERTEAMS[$(( $CURPLAYERCOLOR % 10 ))]=$CURPLAYER
				PLAYERTEAMS[$(( $CURPLAYERCOLOR % 10 + 30 ))]=$CURPLAYER
				PLAYERTEAMS[$(( $CURPLAYERCOLOR % 10 + 90 ))]=$CURPLAYER

				PLAYERS[$CURPLAYER]="$CURPLAYERCOLOR"
				PLAYERS[$CURPLAYER:money]=${LINE#* }
				PLAYERS[${FILEDALIAS: -1}:curbase]=0

				TILES[PlayerBase$CURPLAYER]="\\e[${CURPLAYERCOLOR}m${TILES[PlayerBase]}\\e[0m"
				TILEATTRS[PlayerBase$CURPLAYER]="${TILEATTRS[PlayerBase]}"
				FIELDALIASES[$CURPLAYER]="PlayerBase$CURPLAYER"

				: $(( MAXPLAYERS++ ))

				echo "setupField(): player $CURPLAYER added."
				;;
			"map")
				# Set a level width as in the first occured map line:
				(( $FIELDMAXX == 0 )) && FIELDMAXX=${#LINE}

				if (( $FIELDMAXX != ${#LINE} )); then
					echo "setupField(): warning: different field X in line \"$LINE\" ($FIELDMAXX known, ${#LINE} get)."
					sleep 1
				fi

				for (( x = 0; x < FIELDMAXX; x++ )); do
					CURCELL=${LINE:$x:1}
					FIELDALIAS=${FIELDALIASES[$CURCELL]}
					FIELD[$FIELDMAXY,$x]=$FIELDALIAS

					# Set up quick access to player's bases (if such a tile):
					if [[ "$FIELDALIAS" == "PlayerBase"* ]]; then
						CURPLAYER="${FIELDALIAS: -1}"
						source base_updatequickaccess.sh "$FIELDMAXY,$x" "$CURPLAYER"
						#PLAYERBASES[$CURPLAYER:${PLAYERS[$CURPLAYER,curbase]}]="$FIELDMAXY,$x"

						#echo ${PLAYERBASES[$CURPLAYER,${PLAYERS[$CURPLAYER,curbase]}]}
						PLAYERS[$CURPLAYER:curbase]=$(( ${PLAYERS[$CURPLAYER:curbase]} + 1 ))
					fi
				done

				: $(( FIELDMAXY++ ))
				;;
			*)
				echo "setupField(): warinig: unknown section name \"$CURMAPSECTION\"."
				sleep 0.5
				;;
		esac
	done < $MAPFILE
	unset LINE

	CURX=$(( $FIELDMAXX / 2 ))
	CURY=$(( $FIELDMAXY / 2 ))

	echo "setupField(): done reading \"$MAPFILE\"."
	unset MAPFILE
}


# Clear all previous potencially set variables:
source clearvariables.sh

# "Utils" (for the "cut" command):
readonly CLASS_SYMBOL="-f1"
readonly CLASS_MAXHP="-f2"
readonly CLASS_ATK="-f3"
readonly CLASS_BATK="-f4"
readonly CLASS_COST="-f5"
readonly CLASS_RANGE="-f6"
readonly CLASS_ATTR="-f7-"

FIELDMAXX=0
FIELDMAXY=0
SCREENMINX=15
SCREENMINY=3

ROWS=$(stty size | cut -d" " -f1)
COLUMNS=$(stty size | cut -d" " -f2)

# Current cursor x and y:
CURX=0
CURY=0

CURMODE="cursor" # "cursor", "move", "target", "inbase".
PREVMODE=""

TURN=1

# Field variables ([x/y] map layer and quick aliases):
declare -g -A FIELD && declare -g -A FIELDALIASES

# Class "static constants":
# TEAMCLASSES[X] is a X's player available classes (separated by a tab character).
# Get info from CLASSPROPS[X]: 'cut -f"$CLASS_.\*"' or through "obj_getattr.sh".
declare -a -g TEAMCLASSES && declare -g -A CLASSPROPS && declare -g -A CLASSATTRS

# Object variables ([x/y] classes, [x/y] their HP and [x/y] their colors):
#"$OBJECTSMOVE" is a free turns left for the object.
#"$OBJECTSCOLOR" is also the object team (as "($OBJECTCOLORS % 10)").
declare -g -A OBJECTS && declare -g -A OBJECTSHP && declare -g -A OBJECTSMOVE && declare -g -A OBJECTSCOLOR

# Players info:
# MAXPLAYERS is an amount of players.
# PLAYERS[X] is a X's player bases color (from 1 to 6, see escape sequences).
# PLAYERS[X:money] is a X'th player current wealth.
# PLAYERS[X:dead] is a X'th player live state (set to non-empty if player died).
# PLAYERBASES[X:Y] is an array[0..Y] of the "$x,$y" pairs of X's bases.
# PLAYERBASES[X:count] is a maximal index of the X's bases.
# PLAYERS[X:curbase] is an index in the $PLAYERBASES array.
# PLAYERTEAMS[X]=Y means that team number Y has X color (information opposite 
#to "${PLAYERS[X]}", and no matter what case of inscription you will use, e. g. 
#"1", "31" and "91" are same).
# PLAYERS[X:classesamount] is an amount of the available classes for the player X.
declare MAXPLAYERS=1 && declare -g -A PLAYERS && declare -g -A PLAYERBASES && declare -a PLAYERTEAMS

# For UI (units panel):
declare -a -g PLAYERPANELLINESOFS && declare -a -g PLAYERMONEYPANELOFS


setupField "$1"
setupObjectClasses "$2"


echo "setupField(): call to drawfield(): updating field cache..."
source drawfield.sh "updatecache"


#source obj_create.sh "Light tank" "1" "2,2"
#source obj_create.sh "Trike" "1" "2,4"
#source obj_create.sh "Amphybia" "1" "3,3"
#source obj_create.sh "Light tank" "1" "4,7"

#source obj_create.sh "Rocket launcher" "2" "3,7"
#source obj_create.sh "Heavy tank" "2" "5,7"
#source obj_create.sh "BTR" "2" "4,1"

#source drawfield.sh "(from setupgame.sh)"

# Ten times blows up the second (internally "1"st) column:
#for (( ix = 0; ix < 10; ix++ )); do for (( jx = 0; jx < 8; jx++ )); do source tile_explode.sh "$jx,1"; done; done

: '
source obj_move.sh "4,7" "5,7" && sleep 0.4
source obj_move.sh "2,2" "2,3" && sleep 0.4
source obj_attack.sh "2,3" "3,3"  && sleep 0.4
source obj_move.sh "2,3" "2,2"  && sleep 0.4
source obj_move.sh "3,3" "2,3"  && sleep 0.4
source obj_attack.sh "2,2" "2,3"  && sleep 0.4
source obj_attack.sh "2,2" "2,3"  && sleep 0.4

source obj_move.sh "2,4" "2,5"  && sleep 0.4
source obj_move.sh "2,5" "2,6"  && sleep 0.4
source obj_move.sh "2,6" "2,5"  && sleep 0.4
source obj_capturebase.sh "2,5"  && sleep 0.4
source obj_move.sh "3,7" "2,7"  && sleep 0.4
source obj_move.sh "2,7" "2,6"  && sleep 0.4
source obj_move.sh "2,6" "2,5"  && sleep 0.4
source obj_capturebase.sh "2,5"  && sleep 0.4

: ' #'

