#!/bin/bash

########### (Not all keys from here are real because of WIP):
#
# w up			: Move cursor/object up (in base: select prev unit)
# a left		: Move cursor/object left (in base: select prev unit)
# s down		: Move cursor/object down (in base: select next unit)
# d right		: Move cursor/object right (in base: select next unit)
# space enter kp5 : Action key: toggle cursor/object (in base: select unit to produce)
# f 1 kp1 t		: Attack/fire key
#
# e dot rsqbracket kp9 : Next object
# q comma lsqbracket kp7 : Prev object
# E	greater kp+	: Next base
# Q	less kp-	: Prev base
# c slash bslash 0 kp0/ins: Capture base (in base: cancel)
# X doublequotes: End turn
#
# F1			: Help
# F10 M-x ^F4	: Exit
# h F5			: Show all objects health
# m shift-F5	: Show map layer only (without objects)
# ^L ^R			: Redraw screen
#

moveobjkey() {
	# "$1" == "x" or "y";
	# "$2" == "+" or "-".

	if [[ "$1" == "x" ]]; then
		CURO=$CURX
		FIELDMAXO=$FIELDMAXX
	else
		CURO=$CURY
		FIELDMAXO=$FIELDMAXY
	fi

	if [[ ( "$2" == "+" && $CURO -lt $(($FIELDMAXO - 1)) || "$2" == "-" && $CURO -gt 0 ) && $CURMODE != "inbase" ]]; then
		case $CURMODE in
		"cursor")
			[ "$1" == "x" ] && CURX=$(( $CURO "$2" 1 )) || CURY=$(( $CURO "$2" 1 ))
			;;
		"move")
			NEWO=$(( $CURO "$2" 1 ))

			if [ "$1" == "x" ]; then
				source obj_move.sh "$CURY,$CURX" "$CURY,$NEWO"
			else
				source obj_move.sh "$CURY,$CURX" "$NEWO,$CURX"
			fi

			if [[ "$?" == 0 ]]; then
				[ "$1" == "x" ] && CURX=$NEWO || CURY=$NEWO
			fi
			;;
		"target")
			source drawfield.sh "default" "$CURY,$CURX"
			[ "$1" == "x" ] && CURX=$(( $CURO "$2" 1 )) || CURY=$(( $CURO "$2" 1 ))
			source input_targetmode.sh "draw" "$CURY,$CURX"
			;;
		*)
			echo "input(): error: cannot recognize cursor mode \"$CURMODE\"."
			;;
		esac
	fi

	if [[ $CURMODE == "inbase" ]]; then
		[ -z "${INBASEX+x}" ] && INBASEX=0

		INBASEX=$(( $INBASEX "$2" 1 ))
		(( $INBASEX > ${PLAYERS[$TURN:classesamount]} - 1 )) && INBASEX=0
		(( $INBASEX < 0 )) && INBASEX=$(( ${PLAYERS[$TURN:classesamount]} - 1 ))
	fi
}

actionkey() {
	case $CURMODE in
		"cursor")
			if [[ "${OBJECTS[$CURY,$CURX]}" && "${PLAYERTEAMS[${OBJECTSCOLOR[$CURY,$CURX]}]}" == $TURN ]]; then
				CURMODE="move"
			elif [ "${FIELD[$CURY,$CURX]}" == "PlayerBase$TURN" ]; then
				INBASEX=0
				CURMODE="inbase"
			fi
			;;
		"move")
			CURMODE="cursor" ;;
		"target")
			source input_targetmode.sh "cancel" "$CURY,$CURX" ;;
		"inbase")
			# !!!
			SELECTEDCLASS=$( printf "%s\n" "${TEAMCLASSES[$TURN]}" | cut -f $((INBASEX + 1)) )
			SELECTEDCLASSCOST=$( printf "%s\n" "${CLASSPROPS[$SELECTEDCLASS:cost]}" )

			if [ "${PLAYERS[$TURN:money]}" -ge $SELECTEDCLASSCOST ]; then
				source obj_create.sh "$SELECTEDCLASS" "$TURN" "$CURY,$CURX"

				[[ "$?" == 0 ]] && PLAYERS[$TURN:money]=$(( ${PLAYERS[$TURN:money]} - $SELECTEDCLASSCOST ))
			fi

			unset INBASEX

			source drawui.sh "turn" "money"
			CURMODE="cursor"
			;;
		*) echo "input(): error: cannot recognize cursor mode \"$CURMODE\"." ;;
	esac
}

attackkey() {
	if [[ ( "$CURMODE" == "move" || "$CURMODE" == "cursor" ) && "${PLAYERTEAMS[${OBJECTSCOLOR[$CURY,$CURX]}]}" == $TURN ]]; then
		source input_targetmode.sh "prepare" "$CURY,$CURX"
	elif [[ "$CURMODE" == "target" ]]; then
		source input_targetmode.sh "tryattack" "$CURY,$CURX"
		source drawfield.sh "default" "$CURY,$CURX"
	fi
}

capturebasekey() { # And also in-base cancel.
	if [[ "$CURMODE" == "move" || "$CURMODE" == "cursor" ]]; then
		source obj_capturebase.sh "$CURY,$CURX"

		[[ "$?" == 0 ]] && CURMODE="cursor"
	elif [ "$CURMODE" == "inbase" ]; then
		CURMODE="cursor"
		unset INBASEX
	fi
}


endturnkey() {
	[[ "$CURMODE" != "cursor" && "$CURMODE" != "move" ]] && return

	echo -ne "\e[?25h\e[$(($ROWS - 3));1HDo you want to end the turn? [Y/N]"

	local ENDTURNKEYPR=""
	while [[ "$ENDTURNKEYPR" != "n" && "$ENDTURNKEYPR" != "y" ]]; do
		read -n1 -s ENDTURNKEYPR
		declare -l ENDTURNKEYPR="$ENDTURNKEYPR"
	done

	echo -ne "\e[$(($ROWS - 3));1H                                  \e[?25l"

	if [ "$ENDTURNKEYPR" == "y" ]; then
		local ENDGAMEMASK=0

		# For WIP players wealth increases by constant.
		PLAYERS[$TURN:money]=$(( ${PLAYERS[$TURN:money]} + 15 * ${PLAYERBASES[$TURN:count]} ))

		for curObjPos in "${!OBJECTS[@]}"; do
			CUROBJTEAM=$(. obj_getattr.sh "$curObjPos" "team")
			ENDGAMEMASK=$(( $ENDGAMEMASK | ( 2 ** ( $CUROBJTEAM - 1 ) ) ))

			#echo "$curObjPos: \"$(. obj_getattr.sh "$curObjPos" "team")\" with turn \"$TURN\""

			if [[ $CUROBJTEAM -eq $TURN ]]; then
				OBJECTSMOVE[$curObjPos]=$(. obj_getattr.sh "$curObjPos" "range")
			fi
		done

		# If not all players have objects, then check their bases:
		if (( $ENDGAMEMASK != ( 2 ** ( $MAXPLAYERS - 1 ) - 1 ) )); then
			PLAYERSLEFT=0
			LASTLIVEPLAYER=0

			for (( i_end = 1; i_end < $MAXPLAYERS; i_end++ )); do

				# If player lives and if it now has no objects and if it has no bases:
				if [[ -z "${PLAYERS[$i_end:dead]}" && $(( $ENDGAMEMASK & ( 2 ** ($i_end - 1) ) )) && ${PLAYERBASES[$i_end:count]} -eq 0 ]]; then
					PLAYERS[$i_end:dead]=1
					echo -e "\e[?25h\e[$(($ROWS - 4));1H\e[${PLAYERS[$i_end]}mPlayer $i_end\e[0m had been eliminated."
					echo -n "Press any key to continue... "
					read -n1 -s
					echo -ne "\e[?25l\e[$(($ROWS - 4));1H                             \n                             "
				else
					#echo "\"${PLAYERS[$i_end:dead]}\", $(( $ENDGAMEMASK & ( 2 ** ($i_end - 1) ) )), cnt:${PLAYERBASES[$i_end:count]}"
					LASTLIVEPLAYER=$i_end
					: $(( PLAYERSLEFT++ ))
				fi
			done

			if [ $PLAYERSLEFT -eq 1 ]; then
				echo -e "\e[?25h\e[$(($ROWS - 3));1H\e[${PLAYERS[$LASTLIVEPLAYER]}mPlayer $LASTLIVEPLAYER\e[0m wins!"
				GAME_BASH_STRATEGY="exit"
			elif [ $PLAYERSLEFT -eq 0 ]; then
				echo "Draw."
				GAME_BASH_STRATEGY="exit"
			fi
		fi

		CURMODE="cursor"

		PREVTURN=$TURN
		: $(( TURN++ ))
		# Players counts from 1 to 6:
		[ $TURN -ge $MAXPLAYERS ] && TURN=1
		while [ ${PLAYERS[$TURN:dead]} ]; do
			: $(( TURN++ ))
			[ $TURN -ge $MAXPLAYERS ] && TURN=1

			[ $TURN == $PREVTURN ] && break
		done

		#INFOBARCACHEPREVPOS=""
		source drawui.sh "turn" "money"
	fi
}

quickjumpkey() {
	# "$1" is a "base" or "object";
	# "$2" is a "+" or "-".

	if [[ "$CURMODE" == "cursor" ]]; then

		if [[ "$1" == "base" ]]; then
			if [ ${PLAYERBASES[$TURN:count]} -gt 0 ]; then
				# Cycle current base index:
				#PLAYERS[$TURN:curbase]=$(( ${PLAYERS[$TURN:curbase]} "$2" 1 ))

				#echo "before curbase: ${PLAYERS[$TURN:curbase]}" && sleep 0.1

				while true; do
					: $(( PLAYERS[$TURN:curbase]"$2$2" )) # "++" or "--" :) .
					#echo "$2: ${PLAYERS[$TURN:curbase]}" && sleep 0.1
					(( ${PLAYERS[$TURN:curbase]} > ${PLAYERBASES[$TURN:count]} - 1 )) && PLAYERS[$TURN:curbase]=0
					(( ${PLAYERS[$TURN:curbase]} < 0 )) && PLAYERS[$TURN:curbase]=$(( ${PLAYERBASES[$TURN:count]} - 1 ))
					#PLAYERS[$TURN:curbase]=$(( ${PLAYERS[$TURN:curbase]} "$2" 1 ))
					#echo "curbase${PLAYERS[$TURN:curbase]}:\"${PLAYERBASES[$TURN:${PLAYERS[$TURN:curbase]}]}\"" && sleep 0.1

					[ "${PLAYERBASES[$TURN:${PLAYERS[$TURN:curbase]}]}" ] && break
				done

				#echo "cur ${PLAYERS[$TURN:curbase]}: \"${PLAYERBASES[$TURN:${PLAYERS[$TURN:curbase]}]}\""

				NEWPOS="${PLAYERBASES[$TURN:${PLAYERS[$TURN:curbase]}]}"
				CURY=${NEWPOS%,*}
				CURX=${NEWPOS#*,}
			fi
		elif [ "$1" == "object" ]; then
			command
		else
			echo "quickjumpkey(): warning: unknown target \"$1\"."
		fi

	fi
}

showaltfieldkey() {
	source drawfield.sh "$1"

	echo -ne "\e[?25h\e[$(($ROWS - 3));1HPress any key to continue... "
	[ "$1" != "noobjects" ] && echo -ne "\e[$(($CURY + $SCREENMINY));$(($CURX + $SCREENMINX))H"
	read -n1 -s

	echo -ne "\e[$(($ROWS - 3));1H                             \e[?25l"
	source drawfield.sh "default"
}


# Temporarily.
ForWIP_showKeycode() {
	[ "$2" != "esc" ] && echo "Other: \"$1\"." || echo "Escape sequence postfix: \"$1\"."
	echo -ne "\e[?25h"
	source term_util.sh "startecho"
}



echo -ne "\e[?25h" # Shows cursor.

# This command disables echo with "stty", ...
source term_util.sh "stopecho"

#...and this redirection suppresses unbuffered symbols from "read":
read -n1 -s KEYPR > /dev/null

KEYPR=$(echo "$KEYPR" | cat -vT)

echo -ne "\e[?25l" # Hides cursor.


case $KEYPR in
# Not extended keys:
"w") moveobjkey "y" "-" ;;
"a") moveobjkey "x" "-" ;;
"s") moveobjkey "y" "+" ;;
"d") moveobjkey "x" "+" ;;
"1"|"f"|"t") attackkey ;;
"") actionkey ;; # Space, enter and tab won't write with "cat -vT"...
"c"|"/"|"\\"|"0") capturebasekey ;;

"X"|'"') endturnkey ;;

"Q"|"<"|"+") quickjumpkey "base" "-" ;;
"E"|">"|"-") quickjumpkey "base" "+" ;;

"^L"|"^R")
	source drawui.sh "updatepositions" "updatescreen" "field" "unitspanel" "turn"
;;
"h")
	showaltfieldkey "objectshp"
;;
"m")
	showaltfieldkey "noobjects"
;;



# Escape sequences:
"^[")
	read -t0.001 ESCSEQ

	case $ESCSEQ in
		"x"|"[21~"|"[1;5S") # Alt-X, F10 or Ctrl+F4
			GAME_BASH_STRATEGY="exit"
		;;
		"[A") moveobjkey "y" "-" ;; # \
		"[D") moveobjkey "x" "-" ;; # | Arrow keys
		"[B") moveobjkey "y" "+" ;; # |
		"[C") moveobjkey "x" "+" ;; # /

		"[E") actionkey ;; # Keypad "5" (when not numlock).
		"[F") attackkey ;; # Keypad "1"/"End" (when not numlock).
		"[2~") capturebasekey ;; # Keypad "0"/"Ins" (when not numlock).

		"OP") source showhelp.sh ;; # F1.

		"[15~") # F5 (show health)
			showaltfieldkey "objectshp" ;;
		"[15;2~") # Shift-F5 (show map layer)
			showaltfieldkey "noobjects" ;;

		*) # I also use this file for recognize extended keyboard codes, why not?
			[ -z ${GAME_BASH_STRATEGY+x} ] && ForWIP_showKeycode "$ESCSEQ" "esc"
		;; # of *)
	esac
;; # of "^[")


# Other:
*)
	[ -z ${GAME_BASH_STRATEGY+x} ] && ForWIP_showKeycode "$KEYPR" "normal"
;; # of *)
esac
