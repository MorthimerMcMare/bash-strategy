#!/bin/bash

# A variable indicating whether the game is launched:
GAME_BASH_STRATEGY="$date"

# Level, tileset (as a part of the map file) and objects loading:
source setupgame.sh "test.map" "objdata1.obj"

source drawui.sh "updatepositions" "updatescreen" "field" "unitspanel" "turn" "defaultui"

while [[ $GAME_BASH_STRATEGY != "exit" ]]; do
	source input.sh
	source drawui.sh

	PREVMODE=$CURMODE

	source input_util.sh "flush"
	source input_util.sh "echo on"
done

# Nice exit position:
echo -e "\e[$(($ROWS - 2));1H"

# Clearing all in-game variables:
source shutdown.sh
