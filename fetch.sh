#!/bin/sh
# Downloads Piotr Piatek's FX-8000G emulator (Lazarus port) and puts its core
# units in src/ and its ROM/RAM images in rom/. Neither is kept in this repo.
set -e
cd "$(dirname "$0")"

URL=https://pisi.com.pl/piotr433/fx8000el.zip
SHA256=a527b50bd9c3e82f0722aae9c06093ce8242c3b740cf46bdb1531e9090314002  # version 13

mkdir -p downloads src rom
curl -fsSL -o downloads/fx8000el.zip "$URL"

if ! echo "$SHA256  downloads/fx8000el.zip" | sha256sum -c --status; then
  echo "warning: fx8000el.zip differs from version 13, which this was tested with" >&2
fi

rm -rf downloads/fx8000el
mkdir -p downloads/fx8000el
unzip -q -o downloads/fx8000el.zip -d downloads/fx8000el
for f in def cpu decode exec lcd keyboard fa80; do
  cp downloads/fx8000el/$f.pas src/
done
for f in rom0 rom1 charset ram register; do
  cp downloads/fx8000el/$f.bin rom/
done
echo "fetched emulator core into src/ and ROM images into rom/"
