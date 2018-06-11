#!/bin/bash

if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "syntax: $(basename $0) <file.xml>"
    exit 1
fi

./rebar3 as bench do clean, compile

./bench.erl $@
