#!/bin/sh
set -e
cd "$(dirname "$0")"
[ -f src/def.pas ] && [ -f rom/rom0.bin ] || ./fetch.sh
mkdir -p build out
fpc -O2 -Mdelphi -FEbuild -FUbuild src/fxrun.pas
