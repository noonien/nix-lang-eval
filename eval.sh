#!/bin/sh
lang=$1
source=$2
input=$3
if [ -z "$input" ]; then
        input='""'
fi

nix-build --timeout 5 ./eval.nix -A "languages.$lang" --arg source "$source" --arg input "$input"
