#!/usr/bin/env bash -x

export LC_ALL="C"
export LOCALE="C"

UNIDIC_SRC=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

python3 "${DIR}/update_unidic_impl.py" "${UNIDIC_SRC}/lex.csv" "${DIR}/unidic.orig"