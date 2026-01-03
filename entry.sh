#!/bin/sh

UID_DEF=$(id -u mega)
GID_DEF=$(id -u mega)
UID=$(id -u)
GID=$(id -g)

###

cd "$HOME" || exit 1

cat <<EOL
###
##  MEGA CMD server is starting up.
##  You may want to enter an interactive shell by typing ...
##    docker exec -it $(hostname) mega-cmd
###

EOL

echo "[ i ] Version: $(apk info -d megacmd 2>/dev/null | head -n1 | cut -d' ' -f0)"

if [ ! -r /tmp/machine-id ]; then
    random="$(awk 'BEGIN { srand(); print int(rand() * 32768) }' /dev/null)"
    echo "$random" | md5sum | head -c 20 >/tmp/machine-id
fi


###

if [ "${UID}:${GID}" != "${UID_DEF}:${GID_DEF}" ]; then
    echo "[ i ] Detected custom UID/GID - ${UID}:${GID}"
fi

if [ ! -d .megaCmd ]; then
    install -d -m 0700 .megaCmd
fi

ownchk_megacmd="$(stat -c %u:%g .megaCmd)"
if [ "$ownchk_megacmd" != "${UID}:${GID}" ]; then
    echo "[ ! ] Pre-run check failed! Wrong owner of ${HOME}/.megaCmd - got ${ownchk_megacmd}, expected ${UID}:${GID}"
    exit 1
fi


###

exec mega-cmd-server
