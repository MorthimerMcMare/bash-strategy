#!/bin/bash

fatal() {
	echo "shutdown(): fatal: $1"
	kill $$
}

# Clear variables, if possible:
source clearvariables.sh || fatal "cannot clear variables."

unset GAME_BASH_STRATEGY

# Set terminal default (not previous, yeah) settings and show cursor:
source term_util.sh "restoreterminal" || fatal "cannot restore term (stty)."

# Kill the game if first argument is a "error":
[ "$1" == "error" ] && kill $$

# Remove EXIT signal trap:
trap EXIT || fatal "cannot remove the EXIT trap."

# Set nice vertical cursor position:
echo -e "\e[$(($ROWS - 2));1H"
