#!/bin/bash

case $1 in
	"stopecho"|"echo off")
		stty -echo -icanon min 1 time 2
		;;
	"startecho"|"echo on")
		stty echo icanon
		;;
	"storeterminal") # Saves STDIO descriptor.
		exec 3<&0
		;;
	"restoreterminal")
		exec 0<&3
		echo -ne "\e[?25h"
		stty sane
		;;
	"flush")
		while read -t0 UNUSED; do read -t0.001 UNUSED; done
		#[ "$UNUSED" ] && echo "input_util(): ignored sequence postfix: $UNUSED" | cat -v && unset UNUSED
		;;
	*) echo "input_util(): warning: unrecognized option \"$1\"."
		;;
esac
