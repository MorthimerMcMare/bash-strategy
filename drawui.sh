#!/bin/bash

echo -ne "\e[?25h" # Hides cursor.
echo -ne "\e[$(($CURY + $SCREENMINY));$(($CURX + $SCREENMINX))H"
