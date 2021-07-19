#!/bin/bash

drawunitspanel() {
	echo -n ""
}

clearinfobar() {
	# Subtly clear previous output:
	echo -ne "\e[$INFOBARY;${INFOBARX}H                                 "
	echo -ne "\e[$(($INFOBARY + 1));${INFOBARX}H                        "
}

drawinfobar() {
	if [[ $CURMODE != "move" ]]; then
		POS="$CURY,$CURX"
		STR1="${OBJECTS[$POS]}\e[0m: hp ${OBJECTSHP[$POS]}/$(. obj_getattr.sh $POS maxhp), "
		STR1=$STR1"atk $(. obj_getattr.sh $POS attack)($(. obj_getattr.sh $POS backfire))"
		STR2="Moves: ${OBJECTSMOVE[$POS]}/$(. obj_getattr.sh $POS range)"

		#STR1LEN=${}

		PREVINFOBAR1="\e[$INFOBARY;${INFOBARX}H\e[${OBJECTSCOLOR[$POS]}m$STR1"
		PREVINFOBAR2="\e[$(( $INFOBARY + 1 ));${INFOBARX}H$STR2"
	fi

	# Also subtly clearing:
	echo -ne $PREVINFOBAR1'                '$PREVINFOBAR2'                              '
}

while [ "$1" ]; do
	case $1 in
		"field")
			source drawfield.sh "default"
			;;
		"unitspanel")
			drawunitspanel
			;;
		"updatepositions") # Updates draw positions.
			INFOBARX=$(( $SCREENMINX ))
			INFOBARY=$(( $SCREENMINY + $FIELDMAXY + 2 ))
			;;
	esac
	
	shift
done


if [[ "$CURMODE" != "inbase" ]]; then
	if [[ "${OBJECTS[$CURY,$CURX]}" ]]; then
		drawinfobar
	else
		clearinfobar
	fi
else
	drawunitspanel # Not it.
fi


# In-map cursor position draw:
echo -ne "\e[?25h" # Shows cursor.
echo -ne "\e[$(($CURY + $SCREENMINY));$(($CURX + $SCREENMINX))H"

