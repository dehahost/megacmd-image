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

ownchk_megacmd="$(stat -c %u:%g /home/mega/.megaCmd)"
if [ "${ownchk_megacmd}" != "1001:1001" ]; then
    echo "[!] Wrong owner of /home/mega/.megaCmd - got ${ownchk_megacmd}, expected 1001:1001"
    exit 1
fi

exec mega-cmd-server
