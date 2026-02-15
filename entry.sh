#!/bin/bash

UID_DEF=$(id -u mega)
GID_DEF=$(id -u mega)
GID=$(id -g)

DATE_FMT="%+4Y-%m-%d %H:%M:%S"

MEGA_STATE_DIR=".megaCmd"
SERVER_LOG="${MEGA_STATE_DIR}/megacmdserver.log"
SERVER_PID="/tmp/megacmdserver.pid"


###
### FUNCTIONS

### - Logging

function log_prefix() {
    local mod dt

    if [[ -n $2 ]]; then
        mod=" | $2"
    fi

    dt=$(date +"$DATE_FMT")

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

    if [[ $1 =~ ^-([epi])$ ]]; then
        state=${BASH_REMATCH[1]}; shift
    fi

    echo "$(log_prefix "$state" "$mod") $*"
}

### - Utils: Autosync

function get_owner() {
    stat -c %u:%g "$1"
}

function is_dir_owner_right() {
    local owner ; owner="$(get_owner "$1")"
    [[ $owner == "${UID}:${GID}" ]]
}

function mega_has_session() {
    mega-whoami >/dev/null 2>&1
}

### - Utils: Runtime

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

### - Runtime

function do_start_server() {
    if is_server_running; then
        log -m "server" -i "MEGAcmd server is running"
        return
    fi

    log -m "server" -p "Starting MEGAcmd server"

    mega-cmd-server >/dev/null 2>&1 &
    local pid=$!
    sleep 1s

    if [[ ! -r "/proc/${pid}/stat" ]]; then
        log -m "server" -e "Unable to start MEGAcmd server"
        echo; cat $SERVER_LOG
        exit 1
    fi

    echo $pid >$SERVER_PID
    log -m "server" -i "MEGAcmd server is running"
}

function do_start_precheck() {
    local

    if [[ "${UID}:${GID}" != "${UID_DEF}:${GID_DEF}" ]]; then
        log -m "precheck" -i "Detected custom UID/GID - ${UID}:${GID}"
    fi

    if [[ ! -d "$MEGA_STATE_DIR" ]]; then
        install -d -m 0700 "$MEGA_STATE_DIR" || exit 1
    fi

    if ! is_dir_owner_right "$MEGA_STATE_DIR"; then
        log -m autosync -e "Wrong owner of ${local_dir} - expected ${UID}:${GID}, got $(get_owner "$MEGA_STATE_DIR")"
        exit 1
    fi
}

function do_stop() {
    local arg_silent arg_signal

    if [[ $1 == "-s" ]]; then
        arg_silent=y; shift
    fi

    if [[ $1 =~ ^[0-9]+$ ]]; then
        arg_signal=$1; shift
    fi

    #

    if [[ -z $arg_silent ]]; then
        echo; log -p "Caught stop signal, shutting down..."
    fi

    if is_server_running; then
        kill "$(get_server_pid)"
        [[ -z $arg_silent ]] && log -i "MEGAcmd server is stopped"
    fi

    if [[ -n $arg_silent && $MEGACMD_LOGLEVEL =~ ^(FULL)?(DEBUG|VERBOSE)$ ]]; then
        log -p "Printing server log..."
        echo; cat $SERVER_LOG
    fi

    exit ${arg_signal:+"$arg_signal"}
}

### - Automation

function do_autologin() {
    if mega_has_session; then
        log -m autologin -i "User session exists, skipping..."
        return
    fi

    local password args

    args=("$MEGACMD_EMAIL")

    if [[ -n $MEGACMD_PASSWORD ]]; then
        password=$MEGACMD_PASSWORD
    fi

    if [[ -n $MEGACMD_PASSWORD_FILE ]]; then
        local _secret_src=$MEGACMD_PASSWORD_FILE

        if [[ -r "/run/secrets/${MEGACMD_PASSWORD_FILE}" ]]; then
            log -m autologin -i "Loading password from secret - ${MEGACMD_PASSWORD_FILE}"
            _secret_src="/run/secrets/${MEGACMD_PASSWORD_FILE}"
        else
            log -m autologin -i "Loading password from file - ${_secret_src}"
        fi

        if [[ ! -r $_secret_src ]]; then
            log -m autologin -e "Password file \"${_secret_src}\" is not readable"
            do_stop -s 1
        fi

        if [[ -n $password ]]; then
            log -m autologin -i "Beware: MEGACMD_PASSWORD_FILE overrides MEGACMD_PASSWORD"
        fi

        password=$(<"$_secret_src")
    fi

    if [[ -z $password || $password =~ ^[[:space:]]*$ ]]; then
        log -m autologin -e "Password is empty"
        do_stop -s 1
    fi

    args+=("$password")

    if [[ -n $MEGACMD_TOTP ]]; then
        if [[ ! $MEGACMD_TOTP =~ ^[0-9]{6}$ ]]; then
            log -m autologin -e "MEGASYNC_TOTP has invalid format - expected 6 digits, got \"${MEGACMD_TOTP}\""
            do_stop -s 1
        fi

        args=("--auth-code=${MEGACMD_TOTP}" "${args[@]}")
    fi

    log -m autologin -p "Attempting to login as ${MEGACMD_EMAIL}..."

    timeout -s 9 30s mega-login "${args[@]}" 2>&1

    local _login_rc=$?
    if [[ $_login_rc -ge 124 && $_login_rc -le 127 ]] || [[ $_login_rc -eq 137 ]]; then
        # Usually mistyped email and password causes mega-login to hang
        log -m autologin -e "Login timed out! Check that your login details are correct"
        do_stop -s 1
    elif [[ $_login_rc -ge 1 ]]; then
        # Usually old TOTP fails the command
        log -m autologin -e "Login failed! Isn't the TOTP token outdated?"
        do_stop -s 1
    fi

    log -m autologin -i "Logged in"
}

function do_autosync() {
    if ! mega_has_session; then
        log -m autosync -e "User session does not exists! Please login first to use this feature."
        return
    fi

    ###

    local sync_list
    IFS="," read -r -a sync_list <<<"$MEGACMD_SYNC_DIRS"

    for sync_item in "${sync_list[@]}"; do
        local local_dir remote_dir

        IFS=":" read -r local_dir remote_dir <<<"$(echo "$sync_item" | xargs)"

        if [[ -z $local_dir || -z $remote_dir ]]; then
            log -m autosync -e "Wrong sync definition - '${sync_item}'"
            do_stop -s 1
        fi

        # - Check local dir

        if [[ ! -d "$local_dir" ]]; then
            log -m autosync -e "Local folder does not exist - ${local_dir}"
            do_stop -s 1
        fi

        if ! is_dir_owner_right "$local_dir"; then
            log -m autosync -e "Wrong owner of ${local_dir} - expected ${UID}:${GID}, got $(get_owner "$local_dir")"
            do_stop -s 1
        fi

        # - Check remote dir

        if ! mega-ls "$remote_dir" >/dev/null 2>&1; then
            log -m autosync -e "Remote folder does not exist - ${remote_dir}"
            do_stop -s 1
        fi

        # - Check sync status

        if mega-sync "$local_dir" >/dev/null 2>&1; then
            local sync_status
            sync_status=$(mega-sync --output-cols=LOCALPATH,REMOTEPATH,RUN_STATE,STATUS,ERROR --col-separator=¨ "$local_dir" | awk -F ¨ 'NR%2{split($0,a);next} {for(i in a)$i=(a[i] "=" $i ",")} 1')

            log -m autosync -i "Sync of ${local_dir} is already configured - ${sync_status}"
            continue
        fi

        # - Set up sync

        log -m autosync -p "Setting up sync - ${local_dir}:${remote_dir}..."

        if ! mega-sync "$local_dir" "$remote_dir"; then
            do_stop -s 1
        fi
    done
}


###
### PROGRAM

log -p "Heating up..."

# - Prepare runtime

if [[ ! -r /tmp/machine-id ]]; then
    echo "$RANDOM" | md5sum | head -c 20 >/tmp/machine-id
    log -i "Generated machine-id"
fi

trap do_stop SIGTERM SIGINT

do_start_precheck
do_start_server

# - Run automation

if [[ -n $MEGACMD_EMAIL ]] && [[ -n $MEGACMD_PASSWORD || -n $MEGACMD_PASSWORD_FILE ]]; then
    do_autologin
fi

if [[ -n $MEGACMD_SYNC_DIRS ]]; then
    do_autosync
fi

###

bin_version="$(mega-version)"
pkg_version="$(dpkg -l | grep megacmd | awk '{ print $3 }')"

log -i "Welcome to ${bin_version} (package ${pkg_version})"
log -i "Enter the interactive shell by typing: docker exec -it ${HOSTNAME} mega-cmd"

echo
tail -n+1 -f $SERVER_LOG &
wait
