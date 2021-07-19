#!/bin/bash

source clearvariables.sh

unset GAME_BASH_STRATEGY

source input_util.sh "restoreterminal"

[ "$1" == "error" ] && kill $$
