"""2022 개정 교육과정 성취기준(중학교 · 고등학교 보통교과, 3,838개)을 찾는다. 교과서 PDF가 없을 때 파트 나누기 · 범위 정하기의 기준.
사용: python3 find_standards.py --subject 과학 --level middle --any "별,은하,우주"     # 키워드로
      python3 find_standards.py --subject 과학 --level middle --list                 # 과목 전체를 영역 순서대로
      python3 find_standards.py --code "[9과15-01]"                                  # 코드로 원문
      python3 find_standards.py --subjects --level high                               # 과목 이름 목록
  --level: middle(중학교) · high(고등학교). --subject는 과목 이름 일부(예: 지구과학, 통합과학, 한국지리)
읽는 곳: ../data/curriculum-2022.json.gz (출처 data/CURRICULUM-NOTICE.md). 2026-1호 개정분은 반영되지 않았다.
"""
import argparse, gzip, json, os, sys

DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "curriculum-2022.json.gz")
ap = argparse.ArgumentParser()
ap.add_argument("--subject", default="")
ap.add_argument("--level", choices=["middle", "high"])
ap.add_argument("--any", default="", help="원문 · 영역에 하나라도 들어 있으면(쉼표로)")
ap.add_argument("--code", default="")
ap.add_argument("--list", action="store_true")
ap.add_argument("--subjects", action="store_true")
a = ap.parse_args()
items = json.loads(gzip.open(DATA).read())["items"]
if a.level: items = [x for x in items if x["level"] == a.level]
if a.subjects:
    seen = {}
    for x in items: seen.setdefault((x["level"], x["subject"]), 0); seen[(x["level"], x["subject"])] += 1
    for (lv, s), n in seen.items(): print(f"{'중' if lv == 'middle' else '고'}\t{s}\t{n}개")
    sys.exit()
if a.subject: items = [x for x in items if a.subject.replace(" ", "") in x["subject"].replace(" ", "")]
if a.code: items = [x for x in items if x["code"] == a.code.strip()]
words = ["".join(w.split()) for w in a.any.split(",") if w.strip()]
if words: items = [x for x in items if any(w in "".join((x["text"] + x["domain"]).split()) for w in words)]
if not (a.list or a.code or words):
    sys.exit("--any, --code, --list 중 하나를 주세요")
domain = None
for x in items:
    if x["domain"] != domain:
        domain = x["domain"]; print(f"\n■ {x['subject']} · {domain}")
    print(f"{x['code']} {x['text']}")
print(f"\n{len(items)}개", file=sys.stderr)
