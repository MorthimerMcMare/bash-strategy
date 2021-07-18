#!/bin/bash

# "$1" must be a string type of the target mode action.
# "$2" is a pair "$x,$y" of the target[er] coordinates.

if [[ -z "$1" || ! -z "$3" ]]; then
	echo "input_targetmode(): wrong number of arguments."
	echo "Usage: <string:whattodo> [<int:targx>,<int:targy> (if needed)]."
	echo "<string:whattodo> may be \"prepare\", \"draw\", \"tryattack\" or \"cancel\"."
	source shutdown.sh error
elif [[ -z ${GAME_BASH_STRATEGY+x} ]]; then
	echo "input_targetmode(): game not launched."
	source shutdown.sh error
fi


absdelta() {
	(( $1 - $2 < 0 )) && echo $(( $2 - $1 )) || echo $(( $1 - $2 ))
}

cleartargetmode() {
	source drawfield.sh "default" "$CURY,$CURX"

	CURX=$TARGETERX
	CURY=$TARGETERY
	CURMODE="$PRETARGETMODE"

	# If attacker dies:
	[[ ! -z ${OBJECTS[$TARGETERPOS]} ]] && CURMODE="cursor"

	unset TARGETERTEAM
	unset TARGETERPOS
	unset TARGETERX
	unset TARGETERY
	unset PRETARGETMODE
}

if [[ -z ${TARGETERPOS+x} && "$1" != "prepare" ]]; then
	echo "input_targetmode(): error: main functions called before initialisiation."
	source shutdown.sh "error"
fi

case $1 in
	"prepare")
		if [[ ${OBJECTS[$2]} ]]; then
			PRETARGETMODE="$CURMODE"
			CURMODE="target"
			TARGETERY=$(( $(echo "$2" | cut -d"," -f1) ))
			TARGETERX=$(( $(echo "$2" | cut -d"," -f2) ))
			TARGETERPOS="$TARGETERY,$TARGETERX"
			TARGETERTEAM=$(. obj_getattr.sh "$TARGETERPOS" "team")
		fi
		;;
	"draw")
		CURYOFS=$(( $CURY + $SCREENMINY ))
		CURXOFS=$(( $CURX + $SCREENMINX ))

		ATTACKRANGE=1
		XDELTA=$(absdelta "$CURX" "$TARGETERX")
		YDELTA=$(absdelta "$CURY" "$TARGETERY")
		TARGETERATTR="$(. obj_getattr.sh "$TARGETERPOS" "attr")"

		if [[ $TARGETERATTR == *"atkRange:"* ]]; then
			ATTACKRANGE=$(echo "$TARGETERATTR" | sed "s/atkRange:\([[:digit:]]\)+/\1/1")  #"#
		fi

		# Red if out of range, gray if no object, and yellow on 
		TARGETCOLOR=31
		if (( $XDELTA + $YDELTA <= $ATTACKRANGE )); then
			if [[ ${OBJECTS[$2]} && $(. obj_getattr.sh "$2" "team") != $TARGETERTEAM ]]; then
				TARGETCOLOR=93
			else
				TARGETCOLOR=37
			fi
		fi

		echo -ne "\e[?25l"
		echo -e "\e[$CURYOFS;${CURXOFS}H\e[${TARGETCOLOR}mX\e[0m"
		;;
	"tryattack")
		#echo "targ OBJECTS[$2]: \"${OBJECTS[$2]}\"" && echo "targ OBJECTSHP[$2]: \"${OBJECTSHP[$2]}\"" && sleep 1
		if [[ ${OBJECTS[$2]} && $(. obj_getattr.sh "$2" "team") != $TARGETERTEAM ]]; then
			source obj_attack.sh "$TARGETERPOS" "$2"
		fi
		#echo "x OBJECTS[$2]: \"${OBJECTS[$2]}\"" && echo "x OBJECTSHP[$2]: \"${OBJECTSHP[$2]}\"" && sleep 1
		cleartargetmode
		;;
	"cancel")
		cleartargetmode
		;;
	*)
		echo "input_targetmode(): error: unknown action \"$1\"."
		source shutdown.sh "error"
		;;
esac
