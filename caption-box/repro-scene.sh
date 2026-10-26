# scene.sh NAME W H BG TEXT  -> NAME.fcproj with the background still and one caption on C1
set -e
n=$1; w=$2; h=$3; bg=$4; txt=$5
rm -f $n.fcproj
filmcraft-cli --compact --save-as $PWD/$n.fcproj exec file.newSequence name=$n width=$w height=$h fps=24 >/dev/null
item=$(filmcraft-cli --compact --project $n.fcproj --save exec file.import "{\"paths\":[\"$PWD/$bg\"]}" | python3 -I -c "import json,sys;d=json.load(sys.stdin);print((d.get('items') or [d.get('item')])[0])")
python3 -I - "$item" "$txt" > $n.jsonl <<'PY'
import json,sys
item=int(sys.argv[1]); t=sys.argv[2]
for c in [("timeline.place",{"item":item,"track":"V1","seconds":0,"insert":False,"duration":254016000000*6}),
          ("captions.newTrack",{"format":"Subtitle","name":"Captions"}),
          ("captions.add",{"track":"C1","text":t,"seconds":1,"durationSeconds":3})]:
    print(json.dumps({"id":c[0],"params":c[1]}))
PY
filmcraft-cli --compact --project $n.fcproj --save run $n.jsonl | grep -c '"ok":true'
