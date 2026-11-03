"""시험지 세트(문항 · 정답과 해설 · 검토 용지 + 문항표 엑셀)를 새로 차린다.
사용: python3 exam_new.py <자료폴더> --name 20261103_역학과에너지 --school "○○고등학교" --year "2026학년도 2학기"
                          --exam 기말고사 --subject "역학과 에너지" [--area "과학탐구 영역"] [--period 4]
만드는 것: <자료폴더>/작업/원본(서식 · 문항.typ · 성취기준.typ · brand.typ · print.json), 작업/그림, 작업/참고원본/회색, 작업/검토스캔
그다음: 성취기준.typ · 문항.typ를 채우고 python3 exam_build.py <자료폴더>
"""
import argparse, json, os, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
TPL = os.path.join(HERE, "..", "templates", "exam")
ap = argparse.ArgumentParser()
ap.add_argument("dir"); ap.add_argument("--name", required=True, help="날짜_과목(띄어쓰기 없이), 예 20261103_역학과에너지")
ap.add_argument("--school", default="○○고등학교"); ap.add_argument("--year", default=""); ap.add_argument("--exam", default="기말고사")
ap.add_argument("--subject", required=True); ap.add_argument("--area", default="과학탐구 영역"); ap.add_argument("--period", default="4")
a = ap.parse_args()
work = os.path.join(os.path.abspath(a.dir), "작업"); src = os.path.join(work, "원본")
if os.path.exists(os.path.join(src, "문항.typ")):
    raise SystemExit(f"이미 있습니다: {src}/문항.typ (덮어쓰지 않음)")
os.makedirs(src, exist_ok=True)
sub = {"{SCHOOL}": a.school, "{YEAR}": a.year, "{EXAM}": a.exam, "{SUBJECT}": a.subject, "{AREA}": a.area, "{PERIOD}": a.period, "{NAME}": a.name}
for f in os.listdir(TPL):
    t = open(os.path.join(TPL, f), encoding="utf-8").read()
    for k, v in sub.items(): t = t.replace(k, v)
    open(os.path.join(src, f), "w", encoding="utf-8").write(t)
json.dump({"name": a.name, "kind": "시험지"}, open(os.path.join(src, "print.json"), "w", encoding="utf-8"), ensure_ascii=False)
for d in ("그림", "참고원본/회색", "검토스캔", "확인"):
    os.makedirs(os.path.join(work, d), exist_ok=True)
open(os.path.join(work, "검토스캔", "여기에_스캔본을_넣으세요.txt"), "w", encoding="utf-8").write(
    "검토 용지에 체크 · 메모한 것을 스캔(사진)해 이 폴더에 넣고 AI에게 「검토스캔 반영해 줘」라고 하면, 읽고 고쳐 판을 올립니다.\n")
print("만듦:", src)
print("다음: 성취기준.typ · 문항.typ를 채우고, 그림은 작업/그림/ · 참고 원본은 작업/참고원본/에 두고 python3", os.path.join(HERE, "exam_build.py"), a.dir)
