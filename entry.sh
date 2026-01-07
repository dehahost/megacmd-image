#!/bin/bash

UID_DEF=$(id -u mega)
GID_DEF=$(id -u mega)
GID=$(id -g)

SERVER_LOG=".megaCmd/megacmdserver.log"
SERVER_PID="/tmp/megacmdserver.pid"


###
### FUNCTIONS

### - Logging

function log_prefix() {
    local mod dt

    if [[ -n $2 ]]; then
        mod=" | $2"
    fi

    dt=$(date +"%F %T")

    case $1 in
        "e")    echo -n "[${dt}][ !${mod} ]" ;;
        "p")    echo -n "[${dt}][ >${mod} ]" ;;
        "i"|*)  echo -n "[${dt}][ i${mod} ]" ;;
    esac
}

function log() {
    local mod state

    if [[ $1 == "-m" && ! $2 =~ $^|^- ]]; then
        mod=$2; shift 2
    fi

    if [[ $1 =~ ^-?([epi])$ ]]; then
        state=${BASH_REMATCH[1]}; shift
    fi

    echo "$(log_prefix "$state" "$mod") $*"
}

### - Runtime

function get_server_pid() {
    [[ ! -r $SERVER_PID ]] && return 1

    local pid ; pid=$(<$SERVER_PID)

    [[ ! $pid =~ ^([2-9]|[1-9][0-9]+)$ ]] && return 1

    echo "$pid"
}

function is_server_running() {
    local pid ; pid=$(get_server_pid) || return 1

    if [[ ! -r "/proc/${pid}/stat" ]]; then
        rm $SERVER_PID
        return 1
    fi
}

function do_start_server() {
    if is_server_running; then
        log -m "server" i "MEGAcmd server is running"
        return
    fi

    log -m "server" p "Starting MEGAcmd server"

    echo -e "--- $(date +"%F %T") ---" >$SERVER_LOG
    mega-cmd-server >>$SERVER_LOG &
    local pid=$!
    sleep 1s

    if [[ ! -r "/proc/${pid}/stat" ]]; then
        log -m "server" e "Unable to start MEGAcmd server"
        cat $SERVER_LOG
        exit 1
    fi

    echo $pid >$SERVER_PID
    log -m "server" i "MEGAcmd server is running"
}

function do_precheck() {
    local owner_megacmd

    if [[ "${UID}:${GID}" != "${UID_DEF}:${GID_DEF}" ]]; then
        log -m "precheck" i "Detected custom UID/GID - ${UID}:${GID}"
    fi

    if [[ ! -d .megaCmd ]]; then
        install -d -m 0700 .megaCmd || exit 1
    fi

    owner_megacmd="$(stat -c %u:%g .megaCmd)"
    if [[ $owner_megacmd != "${UID}:${GID}" ]]; then
        log -m "precheck" e "Wrong owner of ${HOME}/.megaCmd - got ${owner_megacmd}, expected ${UID}:${GID}"
        exit 1
    fi
}

function do_stop() {
    echo
    log p "Caught stop signal, so shutting down..."

    if is_server_running; then
        kill "$(get_server_pid)"
        log i "MEGAcmd server is stopped"
    fi

    exit
}

### - Automations

function do_autologin() {
    echo TBD
}

function do_autosync() {
    echo TBD
}


###
### PROGRAM

log p "Heating up..."

# - Prepare runtime

if [[ ! -r /tmp/machine-id ]]; then
    echo "$RANDOM" | md5sum | head -c 20 >/tmp/machine-id
fi

trap do_stop SIGTERM SIGINT

do_precheck
do_start_server

# - Run automation

if [[ -n $MEGASYNC_EMAIL ]] && [[ -n $MEGASYNC_PASSWORD || -n $MEGASYNC_PASSWORD_FILE ]]; then
    do_autologin
fi

if [[ -n $MEGASYNC_DIR ]]; then
    do_autosync
fi

###

log i "Welcome to $(mega-version) (package $(apk info -d megacmd 2>/dev/null | head -n1 | cut -d' ' -f0))"
log i "Enter the interactive shell by typing: docker exec -it $(hostname) mega-cmd"

echo
tail -n+1 -f $SERVER_LOG &
wait "$(get_server_pid)"
