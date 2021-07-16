#!/bin/bash

source clearvariables.sh

unset GAME_BASH_STRATEGY

[ "$1" == "error" ] && kill $$
