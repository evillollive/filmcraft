#!/bin/sh
# Place a 3840x2160 template (text layer with Uniform Scale off) on 3840x2160 and 1920x1080 sequences.
# Usage: sh repro.sh repro_3840x2160_uniform_off.fcgt
set -e
T="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
OUT="${TMPDIR:-/tmp}/fcgt-scale-repro"; mkdir -p "$OUT"
for size in 3840x2160 1920x1080 1080x1920; do
  W=${size%x*}; H=${size#*x}
  printf '%s\n' \
    "{\"id\":\"file.newSequence\",\"params\":{\"name\":\"repro\",\"width\":$W,\"height\":$H,\"fps\":25}}" \
    "{\"id\":\"graphics.template.apply\",\"params\":{\"template\":\"$T\",\"time\":0,\"track\":1}}" \
    | filmcraft-cli --compact --save-as "$OUT/$size.fcproj" run - >/dev/null
  filmcraft-cli --project "$OUT/$size.fcproj" render --seconds 0.5 --out "$OUT/$size.png"
  echo "$OUT/$size.png"
done
