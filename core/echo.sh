#!/bin/bash
# grbl core echo module for printing out data and configures from run environment
# casa@ujo.guru 2023

echo.main () {
    gr.msg "$@"
}

# TBD to run environment and echo variables out of it 'gr echo hello to you too --english' -s 


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
# run entry function only is called from terminal
    gr.debug "documentation: http://localhost:8181/doku.php?id=grbl:modules:as_library"
    echo.main "$@"
fi

