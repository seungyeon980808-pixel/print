"""문항표 엑셀: 작업/원본/문항.typ → typst query(문항표.typ) → 결과/<이름>_시험지_<판>_문항표.xlsx
사용: python3 exam_table.py <자료폴더> --name 20261103_역학과에너지 --v v7   (exam_build.py가 부른다)"""
import argparse, json, os, subprocess, sys
from collections import Counter
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill, Border, Side

HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser(); ap.add_argument("dir"); ap.add_argument("--name", required=True); ap.add_argument("--v", required=True)
a = ap.parse_args()
base = os.path.abspath(a.dir); work = os.path.join(base, "작업"); src = os.path.join(work, "원본")
r = subprocess.run(["typst", "query", "--root", work, "--font-path", os.path.join(HERE, "..", "fonts"),
                    "문항표.typ", "<rows>", "--field", "value", "--one"], cwd=src, capture_output=True, text=True)
if r.returncode: sys.exit(r.stderr)
rows = json.loads(r.stdout)
head = ["번호", "성취기준 코드", "난이도", "변형 정도", "출처 종류", "근거(기출 출처·교과서 쪽)", "답 형식", "자료 구성", "계산 여부",
        "정답", "배점", "발문", "〈보기〉", "선지 ①", "선지 ②", "선지 ③", "선지 ④", "선지 ⑤", "해설", "그림 파일 이름", "원본 자료 파일(작업/참고원본)", "변형 방법"]
wb = Workbook(); ws = wb.active; ws.title = "문항표"
ws.append(head)
for q in rows:
    figs = "\n".join(f"{a.name}_{a.v}_{f}.png" for f in q["figs"])
    ask = (q["lead"].strip() + "\n" + q["ask"].strip()).strip()
    ws.append([q["no"], q["std"], q["level"], q["change"], q["src"], q["source"], q["form"], q["data"], q["calc"],
               q["answer"], q["points"], ask, q["bogi"], *q["choices"], q["explain"], figs, q["orig"], q["how"]])
thin = Side(style="thin", color="BBBBBB")
widths = [6, 13, 7, 7, 10, 34, 8, 11, 8, 6, 6, 60, 40, 12, 12, 12, 12, 12, 60, 34, 40, 50]
for i, w in enumerate(widths, 1):
    ws.column_dimensions[ws.cell(1, i).column_letter].width = w
for row in ws.iter_rows():
    for c in row:
        c.alignment = Alignment(wrap_text=True, vertical="top")
        c.border = Border(top=thin, bottom=thin, left=thin, right=thin)
for c in ws[1]:
    c.font = Font(bold=True, color="FFFFFF"); c.fill = PatternFill("solid", fgColor="1E4D8C")
    c.alignment = Alignment(wrap_text=True, vertical="center", horizontal="center")
ws.freeze_panes = "B2"
s = wb.create_sheet("조건별 개수")
s.append(["조건", "값", "문항 수"])
for key, label in (("src", "출처"), ("change", "변형 정도"), ("level", "난이도"), ("form", "답 형식"), ("data", "자료 구성"), ("calc", "계산")):
    for k, n in sorted(Counter(q[key] for q in rows).items()):
        s.append([label, k, n])
s.append(["배점", "합계", sum(q["points"] for q in rows)])
for col, w in zip("ABC", (12, 14, 10)): s.column_dimensions[col].width = w
out = os.path.join(base, "결과", f"{a.name}_시험지_{a.v}_문항표.xlsx")
wb.save(out); print("만듦:", out, f"({len(rows)}문항)")
