#!/bin/bash

########### (Now there's no real keys because of WIP):
#
# w up			: Move cursor/object up (in base: select prev unit)
# a left		: Move cursor/object left (in base: select prev unit)
# s down		: Move cursor/object down (in base: select next unit)
# d right		: Move cursor/object right (in base: select next unit)
# space enter kp5 : Action key: toggle cursor/object (in base: select unit to produce)
# f 1 kp1		: Attack/fire key
#
# e tab dot		: Next object
# q shift-tab comma : Prev object
# E	greater		: Next base
# Q	less		: Prev base
# c	slash bslash: Capture base
# X doublequotes: End turn
#
# F1			: Help
# F10 M-x ^F4	: Exit
# h F5			: Show all objects health
# m shift-F5	: Show map layer only (without objects)
# L ^L ^R		: Redraw screen
#//1..9 kp1..kp9: Select object // Looks hard to realisation.
#

echo -ne "\e[?25h" # Shows cursor.

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


read -n1 -s KEYPR
KEYPR=$(echo "$KEYPR" | cat -vT)

case $KEYPR in
# Not extended keys:
"w") moveobjkey "y" "-" ;;
"a") moveobjkey "x" "-" ;;
"s") moveobjkey "y" "+" ;;
"d") moveobjkey "x" "+" ;;
"1"|"f") attackkey ;;
"") actionkey ;; # Space and enter won't write with "cat -vT"...
"c"|"/"|"\\") capturebasekey ;;

"^L"|"^R")
	clear
	source drawfield.sh "default"
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
		*)
			#echo "Escape sequence postfix: \"$ESCSEQ\"."
		;; # of *)
	esac
;; # of "^[")


# Other:
*)
	#echo "Other ($KEYPR)"
;; # of *)
esac


# Attempt to flush stdin:
#if [ -t 0 ]; then
#	while read -t0 UNUSED; do read -t0.001 UNUSED; done
#	[ ! -z "$UNUSED" ] && echo "input(): ignored sequence postfix: $UNUSED" | cat -v && unset UNUSED
#fi
