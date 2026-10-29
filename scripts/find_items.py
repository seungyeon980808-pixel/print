"""평가원 수능·모의평가 기출(2007–2027, 19,760문항)에서 키워드로 후보 문항을 찾아 CSV로 뽑는다.
사용: python3 find_items.py --any "연주 시차,겉보기 등급" [--all "등급"] [--not "광도,반지름"] [--subj e1,e2] [--years 2017-2027] [--out 후보.csv]
과목 코드: p1 p2 물리학Ⅰ·Ⅱ · c1 c2 화학 · b1 b2 생명과학 · e1 e2 지구과학 · kor 국어 · eng 영어 · math 수학
          korea_geography world_geography east_asia_history world_history economics society_culture
          life_ethics ethics_thought politics_law law_politics
읽는 곳: ../data/kice-questions.json.gz (exam-search 저장소의 문항 글 색인을 묶은 것)
주의: PDF에서 뽑은 글이라 일부는 글자를 못 읽었다(quality=unreadable 약 5%). 꼭 필요한 문항은 사용자에게 번호로 받는다.
"""
import argparse, csv, gzip, json, os, sys

DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "kice-questions.json.gz")
ap = argparse.ArgumentParser()
ap.add_argument("--any", default="", help="하나라도 들어 있으면(쉼표로 구분)")
ap.add_argument("--all", default="", help="모두 들어 있어야")
ap.add_argument("--not", dest="nots", default="", help="들어 있으면 표시(수준 밖 용어). 빼지는 않고 뒤로 보냄")
ap.add_argument("--subj", default="", help="과목 코드(쉼표로)")
ap.add_argument("--years", default="", help="학년도 범위, 예: 2017-2027")
ap.add_argument("--out", default="")
a = ap.parse_args()
sp = lambda s: ["".join(w.split()) for w in s.split(",") if w.strip()]
anys, alls, nots, subj = sp(a.any), sp(a.all), sp(a.nots), [x.strip() for x in a.subj.split(",") if x.strip()]
y0, y1 = (int(x) for x in a.years.split("-")) if a.years else (0, 9999)
items = json.loads(gzip.open(DATA).read())["items"]
rows = []
for q in items:
    raw = q.get("text") or ""
    t = "".join(raw.split())   # PDF에서 뽑은 글은 띄어쓰기가 들쭉날쭉하므로 공백을 지우고 비교
    if subj and q.get("subject") not in subj: continue
    if not (y0 <= (q.get("year") or 0) <= y1): continue
    if anys and not any(w in t for w in anys): continue
    if alls and not all(w in t for w in alls): continue
    hit_not = [w for w in nots if w in t]
    rows.append({"id": q["id"], "title": q.get("title", ""), "hits": "/".join(w for w in anys + alls if w in t),
                 "수준밖": "/".join(hit_not), "quality": q.get("textQuality", ""), "snippet": " ".join(raw.split())[:90]})
rows.sort(key=lambda r: (r["수준밖"] != "", r["id"]))
w = csv.DictWriter(open(a.out, "w", newline="", encoding="utf-8") if a.out else sys.stdout, fieldnames=["id", "title", "hits", "수준밖", "quality", "snippet"])
w.writeheader(); w.writerows(rows)
print(f"{len(rows)}문항 (수준 밖 용어 포함 {sum(1 for r in rows if r['수준밖'])})", file=sys.stderr)
