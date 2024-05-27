#!/bin/sh

UID_DEF=$(id -u mega)
GID_DEF=$(id -u mega)
UID=$(id -u)
GID=$(id -g)

###

cd $HOME

cat <<EOL
###
##  MEGA CMD server is starting up.
##  You may want to enter an interactive shell by typing ...
##    docker exec -it $(hostname) mega-cmd
###

EOL
echo -e "\e[2m[i] Version: $(apk info -d megacmd 2>/dev/null | head -n1 | cut -d' ' -f0)\e[0m"

if [ ! -r /tmp/machine-id ]; then
    echo $RANDOM | md5sum | head -c 20 >/tmp/machine-id
fi


###

if [ "${UID}:${GID}" != "${UID_DEF}:${GID_DEF}" ]; then
    echo "[i] Detected custom UID/GID - ${UID}:${GID}"
fi

if [ ! -d .megaCmd ]; then
    install -d -m 0700 .megaCmd
fi

ownchk_megacmd="$(stat -c %u:%g .megaCmd)"
if [ "${ownchk_megacmd}" != "${UID}:${GID}" ]; then
    echo "[!] Pre-run check failed! Wrong owner of /home/mega/.megaCmd - got ${ownchk_megacmd}, expected ${UID}:${GID}."
    exit 1
fi


###

exec mega-cmd-server
