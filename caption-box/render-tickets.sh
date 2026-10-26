#!/bin/bash
# Before/after renders for each caption ticket, each made with that ticket's branch build.
# FilmCraft only: ffmpeg-generated gradient backgrounds, the bundled Inter font.
set -e
REPO=/Users/alexperrault/Developer/Filmcraft/.claude/worktrees/great-stonebraker-3f6269
D="$(cd "$(dirname "$0")" && pwd)"
export CARGO_TARGET_DIR="$REPO/target/agent-capstyle"
CLI="$CARGO_TARGET_DIR/debug/filmcraft-cli"
cd "$D"
ffmpeg -loglevel error -y -f lavfi -i "gradients=s=1920x1080:c0=0x2b5876:c1=0x4e4376:x0=0:y0=0:x1=1920:y1=1080:d=1:seed=7" -frames:v 1 bg-16x9.png
ffmpeg -loglevel error -y -f lavfi -i "gradients=s=1080x1920:c0=0xf7b267:c1=0xf25f5c:x0=0:y0=0:x1=1080:y1=1920:d=1:seed=7" -frames:v 1 bg-9x16.png

# shot DIR NAME W H BG TEXT STYLE_JSON
shot() {
  dir=$1; n=$2; w=$3; h=$4; bg=$5; txt=$6; style=$7
  p="$D/$dir/$n.fcproj"; rm -f "$p"
  "$CLI" --compact --save-as "$p" exec file.newSequence name=$n width=$w height=$h fps=24 >/dev/null
  item=$("$CLI" --compact --project "$p" --save exec file.import "{\"paths\":[\"$D/$bg\"]}" | python3 -I -c "import json,sys;d=json.load(sys.stdin);print((d.get('items') or [d.get('item')])[0])")
  python3 -I - "$item" "$txt" "$style" "$D/$dir/$n.png" > "$D/$dir/$n.jsonl" <<'PY'
import json,sys
item=int(sys.argv[1]); t=sys.argv[2]; style=json.loads(sys.argv[3]); out=sys.argv[4]
style.update({"track":"C1","font":"Inter"})
for c in [("timeline.place",{"item":item,"track":"V1","seconds":0,"insert":False,"duration":254016000000*6}),
          ("captions.newTrack",{"format":"Subtitle","name":"Captions"}),
          ("captions.add",{"track":"C1","text":t,"seconds":1,"durationSeconds":3}),
          ("captions.setStyle",style),
          ("playhead.set",{"seconds":2}),
          ("file.exportFrame",{"target":"program","path":out})]:
    print(json.dumps({"id":c[0],"params":c[1]}))
PY
  "$CLI" --compact --project "$p" run "$D/$dir/$n.jsonl" | grep -c '"ok":true' >/dev/null
  rm -f "$p" "$D/$dir/$n.jsonl"
}

build() { (cd "$REPO" && git checkout -q --detach "$1" && cargo build -q -p filmcraft-cli); }

two=$'A caption that runs across\ntwo lines of text'
long='Captions on vertical video stay clear of the platform buttons'

build captions/3357-font-style
shot 3357 before 1920 1080 bg-16x9.png "$two" '{}'
shot 3357 after 1920 1080 bg-16x9.png "$two" '{"fontStyle":"Regular"}'

build captions/3358-wrap-width
shot 3358 before 1080 1920 bg-9x16.png "$long" '{"size":34}'
shot 3358 after 1080 1920 bg-9x16.png "$long" '{"size":34,"maxWidth":0.52}'

build captions/3355-background-padding
shot 3355 before 1920 1080 bg-16x9.png "$two" '{"size":58}'
shot 3355 after 1920 1080 bg-16x9.png "$two" '{"size":58,"backgroundPadding":[24,14]}'

build captions/3356-corner-radius
shot 3356 before 1080 1920 bg-9x16.png "$long" '{"size":34,"color":"#000000","backgroundColor":"#ffffffff","backgroundPadding":17}'
shot 3356 after 1080 1920 bg-9x16.png "$long" '{"size":34,"color":"#000000","backgroundColor":"#ffffffff","backgroundPadding":17,"cornerRadius":11}'

build captions/3354-block-box
shot 3354 before 1920 1080 bg-16x9.png "$two" '{"size":58,"backgroundColor":"#00000080","backgroundPadding":20}'
shot 3354 after 1920 1080 bg-16x9.png "$two" '{"size":58,"backgroundColor":"#00000080","backgroundPadding":20,"boxMode":"block"}'

(cd "$REPO" && git checkout -q claude/great-stonebraker-3f6269)
ls -la "$D"/*/before.png "$D"/*/after.png
