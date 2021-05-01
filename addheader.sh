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

 # include the 'shared' script.
source "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"/common.sh

show_usage () {
    cat <<EOF
$PROGNAME: add header to header [.h], code [.c], and assembler [.S] files
    
Usage:
    $PROGNAME 

Options:
    --template=file     Path to templete copied to target files 
    --path=path         Path to directory that contain filess to be updated
    --show              Print initial lines of template files
EOF
}

parse_argument template:,path:,show,help "$@"
if [[ $? -eq 0 ]]; then
    die "Use ''$PROGNAME --help'' for list of options!"
fi

get_argument template TEMPLATE
get_argument path PATHDIR
get_argument show SHOW
get_argument help HELP

if [[ -v HELP || \
    ! -v TEMPLATE ]]; then
    show_usage
    exit 0
fi

if [[ ! -f "$TEMPLATE" ]]; then
    die "''$TEMPLATE'' does not exist."
fi

if [[ -v SHOW ]]; then
    head -3 "$TEMPLATE"
    echo -e ".   ...\n"
fi

License () {
    echo "/*"
    while read -r line; do
        echo " * $line"
    done < "$1"
    echo "*/"
}

Update () {
    if [[ -f "$1" ]]; then
        info "Updating: $1"

        License "$TEMPLATE" > $SOURCE_ROOT/.tmp
        cat "$1" | awk -f $SOURCE_ROOT/LICENSE.awk >> $SOURCE_ROOT/.tmp
        mv $SOURCE_ROOT/.tmp "$1"
    fi
}

if [[ ! -d "$PATHDIR" ]]; then
    for filename in "${nonoption[@]}"; do
        Update "$filename"
    done
else
    while read -d '' filename; do
         Update "$filename"
    done < <(find "$PATHDIR" \( \
        -name "*.c" -o \
        -name "*.h" -o \
        -name "*.S" \) \
        -type f -print0)
fi
