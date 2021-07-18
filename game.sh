#!/bin/bash

# A variable indicating whether the game is launched:
GAME_BASH_STRATEGY="$date"

# Level, tileset (as a part of the map file) and objects loading:
source setupgame.sh "test.map" "objdata1.obj"

source drawui.sh

while [[ $GAME_BASH_STRATEGY != "exit" ]]; do
	source input.sh
	source drawui.sh
done

echo -e "\n\n\n\n\n\n\n\n"

# Clearing all in-game variables:
source shutdown.sh
