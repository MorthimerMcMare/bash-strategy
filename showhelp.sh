#!/bin/bash

title() {
	echo -e "\e[3;1H\n === \e[97m$1\e[0m ==="
}

HELPPAGE=0
PREVHELPPAGE=-1

readonly HELP_EXIT=-1
readonly HELP_KEYS=1
readonly HELP_RULES=2

clear

while (( $HELPPAGE != $HELP_EXIT )); do
	echo -e "\e[1;1H\e[0mSelect help page (press the highlighted character):"
	echo -ne "  [\e[93mk\e[0m]eys, [\e[93mr\e[0m]ules, [\e[93mq\e[0m]uit help. \e[?25h"

	source term_util.sh "stopecho"
	read -n1 -s KEYPR > /dev/null
	KEYPR=$(echo "$KEYPR" | cat -vT)

	echo -e "\e[?25l" # Hides cursor.

	case $KEYPR in
	"k"|"K")
		HELPPAGE=$HELP_KEYS
	;;
	"r"|"R")
		HELPPAGE=$HELP_RULES
	;;
	"q"|"Q")
		HELPPAGE=$HELP_EXIT
	;;
	esac

	[ $PREVHELPPAGE -ne $HELPPAGE ] && clear

	case $HELPPAGE in
	$HELP_KEYS)
		title "Keys"
		echo "W, A, S, D, [up], [left], [down], [right]: move cursor/unit."
		echo "[space], [enter], [tab]: (de)select unit under cursor. In base: build new unit."
		echo "F, 1, [keypad end], T: attack key."
		echo
		echo "Shift+E, greater (\">\"), [keypad plus]: set cursor to your next base."
		echo "Shift+Q, less (\"<\"), [keypad minus]: set cursor to your previous base."
		echo "C, slash (\"/\"), backslash (\"\\\"), 0, [keypad insert]:"
		echo "                        capture base. In base: cancel selection."
		echo "Shift+X, quotes ('\"'): end turn."
		echo
		echo "[F1]: this help."
		echo "[F10], Alt+X, Ctrl+[F4]: exit game."
		echo "H, [F5]: show units health."
		echo "M, Shift+[F5]: show map layer only (without units)."
		echo "Ctrl+L, Ctrl+R: redraw screen."
	;;
	$HELP_RULES)
		title "Rules"
		echo -e "\
  This game is a step-by-step (turn-based) strategy; you goal is to capture all \n\
opponent bases and destroy all of its units.\n\n\
  Every unit has next characteristics:
  1) Initial health (\"HP\" at the units panel);
  2) Attack strength (\"ATK\"): how many health points will be subtracted from \n\
    the victim while direct attacking.
  3) Backfire strength (\"bk\"): how many health points will be subtracted from \n\
    the attacker while defending.
  4) Cost: amount of money you must spend to build this unit.
  5) Range/speed (\"Ran\"): how many moves unit has every turn.
  6) Special [WIP]: special abilities like water walk or increased attack range.\n\n\
  Backfire do not depends on free moves left.\n\
  One tile = one unit, so unit above the base will prevent creating new units.\n\
  After creating unit has no moves, so they will be on base at least one turn.\n\
  Capturing base is immediate, so you'll be able to use it in the same turn.\n\
  Units with higher attack ranges will not be harmed by backfire when shoots \n\
farther than victim may reply.
"
	;;
	$HELP_EXIT)
	;;
	*)
		clear
		echo "showhelp(): warning: unknown help page \"$HELPPAGE\"."
		sleep 1
	;;
	esac

	PREVHELPPAGE=$HELPPAGE

done

source drawui.sh "updatepositions" "updatescreen" "field" "unitspanel" "turn"
