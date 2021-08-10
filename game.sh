#!/bin/bash

# A variable indicating whether the game is launched:
GAME_BASH_STRATEGY="$date"

intercept_exit() {
	source shutdown.sh ""
}
trap intercept_exit EXIT

# On initializaton program works with configuration files, so it's needed to 
#store original STDIN, or else an EXIT signal will produce a fatal error in the 
#"shutdown.sh" because of "stty" failure:
source term_util.sh "storeterminal"

# Level, tileset (as a part of the map file) and objects loading:
source setupgame.sh "test.map" "objdata1.obj"

source drawui.sh "updatepositions" "updatescreen" "field" "unitspanel" "turn" "defaultui"

while [[ $GAME_BASH_STRATEGY != "exit" ]]; do
	source input.sh
	source drawui.sh

	PREVMODE=$CURMODE

	source term_util.sh "flush"
	#source term_util.sh "echo on"
done

# Trap "intercept_exit()" will prevent exit without clearing.
