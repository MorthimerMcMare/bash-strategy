# bash-strategy

## Main information

A moddable step-by-step strategy written on the shell scripts.

Besides using [Unix mandatory commands](https://en.wikipedia.org/wiki/List_of_Unix_commands) it uses Bash internal functions (relatively they're extremely fast).

Right now it exactly works under xterm-based terminal emulators and tty-console. Other cases not tested yet.

I invented it with friend some years ago when we only has a pen, a pencil, an eraser, a notebook sheet and about two hours of boring free time :) .

## Custom maps, tiles and units

All default files has its own remarks about modding. In future I'll standardize their structure and add normal API information file.

"`*.map`" is a map file. Has link to the tiles and objects to use.

"`*.tls`" is a file with tiles definition and handling parameters.

"`*.obj`" is a file containing information about units.
