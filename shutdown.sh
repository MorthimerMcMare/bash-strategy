#!/bin/bash

source clearvariables.sh

unset GAME_BASH_STRATEGY

echo -ne "\e[?25h"

[ "$1" == "error" ] && kill $$
