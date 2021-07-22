#!/bin/bash

drawunitspanel() {
	echo -n ""
}

clearinfobar() {
	# With subtly clearing previous output:
	if [ "$1" != "2" ]; then
		echo -ne "\e[$INFOBARY;${INFOBARX}H                                 "
		echo -ne "\e[$(($INFOBARY + 1));${INFOBARX}H                        "
	fi
	if [ "$1" != "1" ]; then
		echo -ne "\e[$INFOBARLOCKY;${INFOBARX}H                                 "
		echo -ne "\e[$(($INFOBARLOCKY + 1));${INFOBARX}H                        "
	fi
}

framecaptions() {
	CAPTION1LEN=${#1}
	CAPTION2LEN=${#2}

	echo -ne "\e[$INFOBARY;1H              \n              \n              \n              "
	echo -ne "\e[90m\e[$INFOBARY;$(( $INFOBARCAPTIONXOFS - $CAPTION1LEN ))H$1 /\e[1D\e[1B\\\\"
	echo -ne "\e[37m\e[$INFOBARLOCKY;$(( $INFOBARCAPTIONXOFS - $CAPTION2LEN ))H$2 /\e[1D\e[1B\\\\"

	#echo -ne "\e[90m\e[$INFOBARY;$(( $INFOBARX - 2 ))H/\e[1D\e[1B\\\\\e[37m\e[1D\e[2B/\e[1D\e[1B\\\\"
}

drawinfobar() {
	[ "$2" == "2" ] && OFS=$INFOBARLOCKY || OFS=$INFOBARY

	#if [ "$INFOBARCACHEPREVPOS" != "$1" ]; then
	STR1="${OBJECTS[$1]}\e[0m: hp ${OBJECTSHP[$1]}/$(. obj_getattr.sh $1 maxhp), "
	STR1=$STR1"atk $(. obj_getattr.sh $1 attack)($(. obj_getattr.sh $1 backfire))"
	STR2="Moves: ${OBJECTSMOVE[$1]}/$(. obj_getattr.sh $1 range)"

		#INFOBARCACHEPREVPOS="$1"
		#INFOBARCACHEPREVSTR1="$STR1"
		#INFOBARCACHEPREVSTR2="$STR2"
	#fi

	echo -ne "\e[$OFS;${INFOBARX}H\e[${OBJECTSCOLOR[$1]}m$STR1                \
\e[$(( $OFS + 1 ));${INFOBARX}H$STR2                "
}

: 'drawturnbar() {
	TURNBARX=0
	drawturnbar_internal() {
		echo -ne "\e[1;${TURNBARX}H\e[${1}mturn\e[$(($CURY + $SCREENMINY));$(($CURX + $SCREENMINX))H" && sleep 0.1
	}

	TURNBARX=$(( $SCREENMINX + $FIELDMAXX / 2 - 6 ))
	echo -ne "\e[1;${TURNBARX}H\e[${PLAYERS[$TURN]}mPlayer $TURN\e[0m "
	TURNBARX=$(( $TURNBARX + 9 ))

	drawturnbar_internal 97
	drawturnbar_internal 37
	drawturnbar_internal 90
	drawturnbar_internal 37
}'

if [ "$1" ]; then

	# Special parameters (if any):
	while [ "$1" ]; do
		case $1 in
			"field")
				source drawfield.sh "default"
				;;
			"unitspanel")
				drawunitspanel
				;;
			"updatepositions") # Updates draw positions.
				INFOBARX=15
				INFOBARCAPTIONXOFS=$(( $INFOBARX - 3 ))
				INFOBARY=$(( $SCREENMINY + $FIELDMAXY + 2 ))
				INFOBARLOCKY=$(( INFOBARY + 3 ))
				;;
			"turn")
				#drawturnbar &
				echo -ne "\e[1;$(( $SCREENMINX + $FIELDMAXX / 2 - 6 ))H\e[${PLAYERS[$TURN]}mPlayer $TURN\e[0m turn"
				;;
			"updatescreen")
				PREVMODE="clrscr();"
				clear
				# To rewriting (copied from "turn" case):
				echo -ne "\e[1;$(( $SCREENMINX + $FIELDMAXX / 2 - 6 ))H\e[${PLAYERS[$TURN]}mPlayer $TURN\e[0m turn"
				;;
			"defaultui")
				source drawui.sh ""
				;;
			*) echo "drawui(): warning: unrecognized option \"$1\"."
				;;
		esac

		shift
	done

else

	# On mode change:
	if [[ $PREVMODE != $CURMODE ]]; then
		case $PREVMODE in
			"cursor") clearinfobar "1" ;;
			"move") [ $CURMODE != "target" ] && clearinfobar "2" ;;
			"target") [ $CURMODE == "cursor" ] && clearinfobar "2" || clearinfobar "1" ;;
		esac
		case $CURMODE in
			"cursor") framecaptions "Cursor" "" ;;
			"move") framecaptions "" "Current"; drawinfobar "$CURY,$CURX" "2" ;;
			"target") framecaptions "Target" "Attacker"; drawinfobar "$TARGETERPOS" "2" ;;
			"inbase") framecaptions "" "" ;;
		esac
	fi


	# Infobar drawing based on current mode:
	case $CURMODE in
		"cursor")
			[ "${OBJECTS[$CURY,$CURX]}" ] && drawinfobar "$CURY,$CURX" "1" || clearinfobar "1"
			;;
		"target")
			if [[ "${OBJECTS[$CURY,$CURX]}" && "$CURY,$CURX" != "$TARGETERPOS" ]]; then
				drawinfobar "$CURY,$CURX" "1"
			else
				clearinfobar "1"
			fi
			;;
		"move") drawinfobar "$CURY,$CURX" "2"
			;;
		"inbase")
			# Here must be a moveable pointer in the units panel.
			;;
		*) echo "drawinfobar(): warning: unrecognized option \"$1\"." ;;
	esac

fi


# In-map cursor position draw:
echo -ne "\e[$(($CURY + $SCREENMINY));$(($CURX + $SCREENMINX))H"
