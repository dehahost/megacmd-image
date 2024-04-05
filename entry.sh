#!/bin/sh

cat <<EOL
##
##  MEGA CMD server is starting up.
##  You may want to enter an interactive shell by typing ...
##    docker exec -it $(hostname) mega-cmd
##
EOL

if [ ! -r /tmp/machine-id ]; then
    echo $RANDOM | md5sum | head -c 20 >/tmp/machine-id
fi

exec mega-cmd-server
