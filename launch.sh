#!/bin/bash

function stop() {
    exit
}
trap stop TERM


cat <<EOL
##
##  MEGA CLI container is now alive.
##  You may want to enter an interactive shell by typing ...
##    podman exec -it $(hostname) mega-cmd
##
EOL

if [[ ! -r /tmp/machine-id ]]; then
    echo $RANDOM | md5sum | head -c 20 >/tmp/machine-id
fi

exec mega-cmd-server
