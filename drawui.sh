#!/bin/bash

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

	STR1="${OBJECTS[$1]:0:20}\e[0m: hp ${OBJECTSHP[$1]}/$(. obj_getattr.sh $1 maxhp), "
	STR1=$STR1"atk $(. obj_getattr.sh $1 attack)($(. obj_getattr.sh $1 backfire))"
	STR2="Moves: ${OBJECTSMOVE[$1]}/$(. obj_getattr.sh $1 range)"

	echo -ne "\e[$OFS;${INFOBARX}H\e[${OBJECTSCOLOR[$1]}m$STR1 \
\e[$(( $OFS + 1 ));${INFOBARX}H$STR2 "
}

drawmoneybar() {
	echo -ne "\e[${PLAYERMONEYPANELOFS[$1]}H\e[90m(\e[0m${PLAYERS[$1:money]}\e[90m\$)"
}

drawunitspanel() {
	CURPANELLINE=0

	alignright() {
		ALIGNTEMPSTR="${CLASSPROPS[$REALNAME:$1]}"
		echo "\e[$(($2 - ${#ALIGNTEMPSTR}))C$ALIGNTEMPSTR"
	}

	nextline() {
		echo -e "\e[${UNITSPANELX}G$1"
		: $(( CURPANELLINE++ ))
	}

	for (( i_upl = 1; i_upl < $MAXPLAYERS; i_upl++ )); do
		# Go to start position:
		echo -ne "\e[$(( $UNITSPANELY + $CURPANELLINE ));${UNITSPANELX}H"

		# Print player name:
		CURPLAYERNAME="Player $i_upl"
		nextline "\e[90m| \e[${PLAYERS[$i_upl]}m$CURPLAYERNAME\e[90m  "

		# Set up a money bar position:
		PLAYERMONEYPANELOFS[$i_upl]="$(( $UNITSPANELY + $CURPANELLINE - 1 ));$(( ${#CURPLAYERNAME} + $UNITSPANELX + 4 ))"
		#echo "[[$i_upl: ${PLAYERMONEYPANELOFS[$i_upl]}]]"

		# Print expanded divisioner in non-compact mode (see "updatepositions"):
		DIVISIONERSTR="\e[1D=^=v================Cost==HP/ATK(bk)/Ran"
		(( $COMPACTSCREEN == 0 )) && DIVISIONERSTR="${DIVISIONERSTR}/Special====="
		nextline $DIVISIONERSTR

		# Set up start position for future units choice action:
		PLAYERPANELLINESOFS[$i_upl]=$CURPANELLINE

		#"${TEAMCLASSES[$PLAYERNUM]}" == *"$OBJNAME"*
		# Print out units and their characteristics for all players:
		TEMPLINE="${TEAMCLASSES[$i_upl]}	"

		while [ "$TEMPLINE" ]; do
			REALNAME=${TEMPLINE%%	*}	# Internal used name.
			REALNAME=${REALNAME##*	}
			TRUNCNAME=${REALNAME:0:15}	# Name truncate to 15 characters.
			#printf "%s\n" "\"$NAME\", \"${TEAMCLASSES[$i_upl]}\""

			SYMBSTR="\e[0m${CLASSPROPS[$REALNAME:symb]:0:1}"
			NAMESTR="\e[0m$TRUNCNAME\e[$((16 - ${#REALNAME}))C"
			# It's better not to set costs > 999$. At least at the moment.
			COSTSTR="\e[1D$(alignright "cost" "4")\$"
			HPSTR="\e[97m$(alignright "maxhp" "3")\e[90m/"
			ATKSTR="\e[37m$(alignright "atk" "1")\e[90m("
			BATKSTR="\e[90m$(alignright "batk" "2")\e[90m)/"
			RANGESTR="\e[37m$(alignright "range" "3")\e[90m"

			(( $COMPACTSCREEN == 0 )) && RANGESTR="$RANGESTR/ ${CLASSATTRS[$REALNAME]}"
			nextline "$SYMBSTR \e[90m|$NAMESTR$COSTSTR $HPSTR $ATKSTR$BATKSTR$RANGESTR"

			TEMPLINE="${TEMPLINE#*	}"
		done

		drawmoneybar "$i_upl"

		nextline ""
	done
}


clearinbasecursor() {
	# !!!
	#for (( ; ; )); do
		echo -ne "\e[H"
	#done
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
				# (I'll pick up the values later).
				ROWS=$(stty size | cut -d" " -f1)
				COLUMNS=$(stty size | cut -d" " -f2)

				UNITSPANELX=50
				if (( $UNITSPANELX + 60 < $COLUMNS )); then
					COMPACTSCREEN=0
					SCREENMINX=15

					INFOBARX=15
					INFOBARCAPTIONXOFS=$(( $INFOBARX - 3 ))
					INFOBARY=$(( $SCREENMINY + $FIELDMAXY + 2 ))
					INFOBARLOCKY=$(( INFOBARY + 3 ))

					UNITSPANELY=2
				else
					if (( $ROWS < 24 || $COLUMNS < 80 )); then
						echo -e "\e[?25h\e[$(($ROWS - 4));1H\e[1;93mdrawui(): warning: terminal size may be too small."
						echo -n "Press any key to continue... "
						read -n1 -s
						echo -ne "\e[?25l\e[$(($ROWS - 4));1H                             \n                             \e[0m"
					fi
					COMPACTSCREEN=1
					UNITSPANELX=$(( $COLUMNS / 2 - 10 ))
					UNITSPANELY=2

					SCREENMINX=$(( UNITSPANELX / 2 - $FIELDMAXX / 2 ))

					INFOBARX=13
					INFOBARCAPTIONXOFS=$(( $INFOBARX - 3 ))
					INFOBARY=$(( $ROWS - 7 ))
					INFOBARLOCKY=$(( INFOBARY + 3 ))
				fi

				;;
			"turn")
				echo -ne "\e[1;$(( $SCREENMINX + $FIELDMAXX / 2 - 6 ))H\e[${PLAYERS[$TURN]}mPlayer $TURN\e[0m turn:"
				;;
			"money") # Also draws in "drawunitspanel()".
				for (( i_players = 1; i_players < $MAXPLAYERS; i_players++ )); do				
					drawmoneybar "$i_players"
				done
				;;
			"updatescreen")
				PREVMODE="clrscr();"
				clear
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
			"inbase") clearinbasecursor ;;
		esac
		case $CURMODE in
			"cursor") framecaptions "Cursor" "" ;;
			"move") framecaptions "" "Current" ;;
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
