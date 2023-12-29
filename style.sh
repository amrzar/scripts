#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later

export VERSION_CONTROL=none

[[ $# -ne 1 ]] && {
    echo "${0##*/}: input file is missing."
    exit 1
}

#
# These are subset of options that matches the '--linux-style'.
#
# -nbad, --no-blank-lines-after-declarations.
# -bap,  --blank-lines-after-procedures.
# -nbc,  --no-blank-lines-after-commas.
# -nbbo, --break-after-boolean-operator.
# -br,   --braces-on-if-line.
# -brs,  --braces-on-struct-decl-line.
# -cn,   --comment-indentationn.
# -cdn,  --declaration-comment-columnn.
# -ncdb, --no-comment-delimiters-on-blank-lines.
# -ce,   --cuddle-else.
# -cin,  --continuation-indentationn.
# -clin, --case-indentationn.
# -dn,   --line-comments-indentationn.
# -din,  --declaration-indentationn.
# -nfc1, --dont-format-first-column-comments.
# -in,   --indent-leveln.
# -ipn,  --parameter-indentationn.
# -ln,   --line-lengthn.
# -nlp,  --dont-line-up-parentheses.
# -npcs, --no-space-after-function-call-names.
# -nprs, --no-space-after-parentheses.
# -npsl, --dont-break-procedure-type.
# -sai,  --space-after-if.
# -saf,  --space-after-for.
# -saw,  --space-after-while.
# -ncs,  --no-space-after-casts.
# -nsc,  --dont-star-comments.
# -nut,  --no-tabs.
# -sob,  --swallow-optional-blank-lines.
# -nfca, --dont-format-comments.
# -ss,   --space-special-semicolon.
# -iln,  --indent-labeln.
# -lps,  --leave-preprocessor-space
#
#   See https://linux.die.net/man/1/indent
#

#
# -A8,   --style=linux
# -s#,   --indent=spaces=#
# -xV,   --attach-closing-while
# -xU,   --indent-after-parens
# -w,    --indent-preproc-define
# -Y,    --indent-col1-comments
# -m#,   --min-conditional-indent=#
# -p,    --pad-oper
# -xg,   --pad-comma
# -H,    --pad-header
# -k3,   --align-pointer=name
# -xb,   --break-one-line-headers
# -xf,   --attach-return-type
# -c,    --convert-tabs
# -xL,   --break-after-logical
# -xC#,  --max-code-length=#
#
#   See https://astyle.sourceforge.net/astyle.html
#

if [[ -z "${USE_ASTYLE}" ]]; then
    indent -nbad -bap -nbc -nbbo -br -brs -c33 -cd33 -ncdb -ce -ci4 \
        -cli0 -d0 -di1 -nfc1 -i4 -ip0 -l80 -nlp -npcs -nprs -npsl -sai \
        -saf -saw -ncs -nsc -nut -sob -nfca -ss -il1 -lps "${1}" -o "${1}.tmp" 2> /dev/null || {
            rm "${1}.tmp"
            echo "indent: formatting ${1} failed."
            exit 1
        }
else
    astyle --style=linux --indent=spaces=4 --attach-closing-while \
        --indent-after-parens --indent-preproc-define --indent-col1-comments \
        --min-conditional-indent=0 --pad-oper --pad-comma --pad-header \
        --align-pointer=name --break-one-line-headers --attach-return-type \
        --max-code-length=80 --convert-tabs --break-after-logical \
        --mode=c < "${1}" > "${1}.tmp" 2> /dev/null || {
            rm "${1}.tmp"
            echo "astyle: formatting ${1} failed."      
            exit 1
        }
fi

cmp -s "${1}" "${1}.tmp"
[[ $? -eq 0 ]] || {
    echo "Formatted: ${1}"
    mv "${1}.tmp" "${1}"
}

rm -f "${1}.tmp"
