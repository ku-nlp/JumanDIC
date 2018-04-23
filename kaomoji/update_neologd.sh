#!/usr/bin/env bash

export LC_ALL="C"
export LOCALE="C"

NEOLOGD_SRC=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

eval xzgrep -hE ',カオモジ,カオモジ$' "${NEOLOGD_SRC}/seed/*.xz" | cut -d, -f1 > "${DIR}/neologd.orig"