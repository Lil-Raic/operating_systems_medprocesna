#!/usr/bin/env bash

function server_start
{
    ACTUAL_OUTPUT=""
    "${EXEC_SERVER}" > /dev/null &
    SERVER_PID="${!}"
    sleep 0.5
}

function server_stop
{
    ACTUAL_OUTPUT+="$(printf "\npošiljam zastavico '-s'")"
    "${EXEC_CLIENT}" -s
    ACTUAL_EXIT_STATUS="${?}"
    sleep 0.5
}

function server_is_running
{
    if ps -p "${SERVER_PID}" > /dev/null
    then
        ACTUAL_OUTPUT+="$(printf "\nstrežnik zagnan")"
    fi
}

function server_is_stopped
{
    if ! ps -p "${SERVER_PID}" > /dev/null
    then
        ACTUAL_OUTPUT+="$(printf "\nstrežnik ustavljen")"
    fi
}

function send_flag_r
{
    local file_name="${1}"
    
    ACTUAL_OUTPUT+="$(printf "\npošiljam zastavico '-r'\n")"
    ACTUAL_OUTPUT+="$(printf "\n++ vsebina zbirke ${file_name}:")"
    ACTUAL_OUTPUT+="$(printf "\n%s" "$("${EXEC_CLIENT}" -r "${file_name}")")"
    ACTUAL_OUTPUT+="$(printf "\n--")"
    sleep 0.5
}

function create_pipe
{
    local pipe="$(mktemp -u -p . "pipe.XXXXXXXXXX")"
    mkfifo "${pipe}"
    echo "${pipe}"
}

function send_flag_w
{
    local pipe="${1}"
    local file_name="${2}"

    ACTUAL_OUTPUT+="$(printf "\npošiljam zastavico '-w'")"
    cat "${pipe}" | "${EXEC_CLIENT}" -w "${file_name}" &
    sleep 0.5
}

function write_to_pipe
{
    local pipe="${1}"
    local msg="${2}"

    ACTUAL_OUTPUT+="$(printf "\npišem v zbirko")"
    echo "${msg}" > "${pipe}"
    sleep 0.5
}

function create_file
{
    local file_name="${1}"
    local msg="${2}"

    echo "${msg}" > "${file_name}"
}

function print_file
{
    local file_name="${1}"

    ACTUAL_OUTPUT+="$(printf "\n++ vsebina zbirke ${file_name}:")"
    ACTUAL_OUTPUT+="$(printf "\n%s" "$(cat "${file_name}")")"
    ACTUAL_OUTPUT+="$(printf "\n--")"
}
