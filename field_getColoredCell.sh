#!/bin/bash

OUT="\e[0m"

case "$1" in
	".") OUT="\e[32m" ;;
	"#") OUT="\e[90m" ;;
	"=") OUT="\e[34m" ;;
	*) ;;
esac

echo -ne $OUT$1
