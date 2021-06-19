 #!/bin/bash

 #
 # Copyright 2020 Amirreza Zarrabi <amrzar@gmail.com>
 #
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #

SOURCE_ROOT=${0%/*}
PROGNAME=${0##*/}

#
# Set up terminal capabilities (for displaying in bold and colors).
# See terminfo(5) for a list of terminal capability strings.
#

BOLD=$(tput bold) || BOLD=
NORMAL=$(tput sgr0) || NORMAL=
NCOLORS=$(tput colors)

RED=
GREEN=
YELLOW=

#
# We want different foreground color numbers if we have a terminal capable of
# more than 8, because generally the contrast is bad if we use the low-numbered
# colors (bold helps, but only so much).  On terminals truly capable of only 8
# colors, we have to rely on the implementation to provide good contrast.
#

if [[ -n "$NCOLORS" ]]; then
    if [[ $NCOLORS -gt 8 ]]; then
        RED=$(tput setaf 9)
        GREEN=$(tput setaf 10)
        YELLOW=$(tput setaf 11)

    elif [[ $NCOLORS -eq 8 ]]; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
    fi
fi

_echo () {
    echo "${PROGNAME:-(unknown program)}: $BOLD$*$NORMAL"
}

info () {
    _echo "${GREEN}[info] $NORMAL$*" >&2
}

warning () {
    _echo "${YELLOW}[warning] $NORMAL$*" >&2
}

#
# Report unrecoverable error and terminate script.
# @params: a set of strings comprising a human-intelligible message
#
# Note: $EXIT_STATUS, if set in the invoking scope, determines the exit status
# used by this function.
#

die () {
    _echo "${RED}[error] $NORMAL$*" >&2
    exit ${EXIT_STATUS:1}
}

getopt -T || GETOPT_STATUS=$?

if [[ $GETOPT_STATUS -ne 4 ]]; then
    die "getopt from util-linux required"
fi

#
# '$1' are long (multi-character) options to be recognized. More than one option name may
# be specified at once, by separating the names with commas. Each long option name in 
# longopts may be followed by one colon to indicate it has a required argument, 
# and by two colons to indicate it has an optional argument.
#
# See getopt(1) for more detail.
#

nonoption=
declare -A arguments
parse_argument() {
    local opts=$1; shift # ... store getopt options.

    local args=$(getopt -o ''   \
        --longoptions $opts     \
        --name "$PROGNAME" -- "$@") ||
        exit $?

    eval set -- "$args"

    while true; do
        case "$1" in
            (--)
                shift; nonoption=("$@")
                break
                ;;
            (--*)
                if [[ $opts = *${1#--}:* ]]; then
                    arguments[${1#--}]="$2"; shift
                else
                    arguments[${1#--}]=""
                fi
                shift
                ;;
            (*)
                die "parse_argument: internal error!"
                ;;
        esac
    done

    return ${#arguments[@]}
}

get_argument () {
    local -n vn=$2 # ... output parameter.
    if [[ ${arguments[$1]+set} = set ]]; then
        vn=${arguments[$1]}
    elif [[ $# -eq 3 ]]; then
        vn="$3"
    fi
}
