"""임용 패널 원본을 단일 파일 survey/index.html에 넣는다. 반복 실행해도 동일하다."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
p=root/'survey/index.html'
text=p.read_text()
start='<!-- IMYONG PANEL START -->';end='<!-- IMYONG PANEL END -->'
if start in text:
    before,tail=text.split(start,1);_,after=tail.split(end,1)
    text=before.rstrip()+'\n'+after.lstrip('\n')
panel=(root/'survey/imyong-panel.html').read_text()
shared=(root/'survey/imyong-topics.mjs').read_text().replace('export ', '')
taxonomy=json.loads((root/'data/imyong-topics.json').read_text())
for u in taxonomy['units']:
    for t in u['topics']:t.pop('keywords',None)
panel=panel.replace('/* IMYONG_SHARED */',shared).replace('__IMYONG_TAXONOMY__',json.dumps(taxonomy,ensure_ascii=False,separators=(',',':')))
text=text.replace('</body>',f'{start}\n{panel}\n{end}\n</body>')
p.write_text(text)
