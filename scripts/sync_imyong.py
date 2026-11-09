"""exam-search의 원본 색인에서 print용 데이터와 학습 모드 자료를 재현한다."""
import argparse, gzip, json, re, hashlib, unicodedata
from pathlib import Path
from imyong_data import extract_points, load_taxonomy, classify_topics

ap = argparse.ArgumentParser()
ap.add_argument('--library', type=Path, required=True)
args = ap.parse_args()
folder = args.library / 'data' / 'imyong'
items = json.loads((folder / 'questions.json').read_text())['items']
files = json.loads((folder / 'files.json').read_text())
by_name = {f['pdfFile']: f for f in files}
taxonomy=load_taxonomy()
for q in items:
    q['points'], q['pointsEvidence'] = extract_points(q['questionText'])
    q['topicIds'],q['topicEvidence']=classify_topics(q,taxonomy)
(folder / 'questions.json').write_text(json.dumps({'items':items},ensure_ascii=False,separators=(',',':')))
revision=hashlib.sha256((folder / 'questions.json').read_bytes()).hexdigest()
data={'schema':1,'dataVersion':'imyong-2002-2026-v1','topicVersion':taxonomy['version'],'taxonomy':taxonomy,'sourceRevision':revision,'items':items,'files':files}
dest=Path(__file__).resolve().parents[1]/'data'/'imyong-questions.json.gz'
dest.write_bytes(gzip.compress(json.dumps(data,ensure_ascii=False,separators=(',',':')).encode(),mtime=0))
study=[]
for q in items:
    x={k:v for k,v in q.items() if k not in ['text','questionText','curriculum','sourceUrl','sourcePage']}
    x['publicPath']=by_name[q['pdfFile']]['publicPath']
    x['_search']=re.sub(r'\s+','',unicodedata.normalize('NFKC',' '.join([q['title'],q['text'],*q.get('tags',[])])).lower())
    study.append(x)
(folder/'study.json.gz').write_bytes(gzip.compress(json.dumps({'schema':1,'topicVersion':taxonomy['version'],'taxonomy':taxonomy,'items':study},ensure_ascii=False,separators=(',',':')).encode(),mtime=0))
from collections import Counter
print(json.dumps({'questions':len(items),'points':dict(Counter(str(q['points']) for q in items)),'printBytes':dest.stat().st_size},ensure_ascii=False))
