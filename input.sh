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
# e tab dot	kp9	: Next object
# q shift-tab comma kp7 : Prev object
# E	greater kp+	: Next base
# Q	less kp-	: Prev base
# c	slash bslash: Capture base
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
		echo "inbase $2$1"
	fi
}

actionkey() {
	case $CURMODE in
		"cursor")
			if [[ "${OBJECTS[$CURY,$CURX]}" ]]; then
				CURMODE="move"
			elif [[ "${FIELD[$CURY,$CURX]}" == "PlayerBase"* ]]; then
				CURMODE="inbase"
			fi ;;
		"move")
			CURMODE="cursor" ;;
		"target")
			source input_targetmode.sh "cancel" "$CURY,$CURX" ;;
		"inbase")
			CURMODE="cursor" ;;
		*) echo "input(): error: cannot recognize cursor mode \"$CURMODE\"." ;;
	esac
}

attackkey() {
	if [[ "$CURMODE" == "move" || "$CURMODE" == "cursor" ]]; then
		source input_targetmode.sh "prepare" "$CURY,$CURX"
	elif [[ "$CURMODE" == "target" ]]; then
		source input_targetmode.sh "tryattack" "$CURY,$CURX"
		source drawfield.sh "default" "$CURY,$CURX"
	fi
}

capturebasekey() {
	if [[ "$CURMODE" == "move" || "$CURMODE" == "cursor" ]]; then
		source obj_capturebase.sh "$CURY,$CURX"

		[[ "$?" == 0 ]] && CURMODE="cursor"
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
	source input_util.sh "startecho"
}

echo -ne "\e[?25h"

read -n1 -s KEYPR
KEYPR=$(echo "$KEYPR" | cat -vT)

echo -ne "\e[?25l"

# It more or less helps with the repeatable keypress echo:
source input_util.sh "stopecho"

case $KEYPR in
# Not extended keys:
"w") moveobjkey "y" "-" ;;
"a") moveobjkey "x" "-" ;;
"s") moveobjkey "y" "+" ;;
"d") moveobjkey "x" "+" ;;
"1"|"f"|"t") attackkey ;;
"") actionkey ;; # Space and enter won't write with "cat -vT"...
"c"|"/"|"\\") capturebasekey ;;

"^L"|"^R")
	source drawui.sh "updatepositions" "updatescreen" "field" "unitspanel"
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
		
		"[15~") # F5 (show health)
			showaltfieldkey "objectshp" ;;
		"[15;2~") # Shift-F5 (show map layer)
			showaltfieldkey "noobjects" ;;

		*) # I also use that file for recognize extended keyboard codes, why not?
			[ -z ${GAME_BASH_STRATEGY+x} ] && ForWIP_showKeycode "$ESCSEQ" "esc"
		;; # of *)
	esac
;; # of "^[")


# Other:
*)
	[ -z ${GAME_BASH_STRATEGY+x} ] && ForWIP_showKeycode "$KEYPR" "normal"
;; # of *)
esac
