"""시험지 세트를 뽑는다: 결과/<이름>_시험지_<판>.pdf · _해설.pdf · _검토용지.pdf · _문항표.xlsx (+ 작업/확인/ 쪽 그림)
사용: python3 exam_build.py <자료폴더>            지금 판(문항.typ의 V)으로 다시 뽑기(같은 판 덮어씀)
      python3 exam_build.py <자료폴더> --next     판을 올려 새로 뽑기(이전 판 파일은 남김, 그림도 새 판 이름으로 복사)
      --no-png  확인용 쪽 그림을 만들지 않음
root는 작업/ — 그림은 작업/그림/, 참고 원본은 작업/참고원본/(검토 용지에는 참고원본/회색/).
"""
import argparse, glob, json, os, re, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.abspath(os.path.join(HERE, "..", "fonts"))
ap = argparse.ArgumentParser()
ap.add_argument("dir"); ap.add_argument("--next", action="store_true"); ap.add_argument("--no-png", action="store_true")
a = ap.parse_args()
base = os.path.abspath(a.dir); work = os.path.join(base, "작업"); src = os.path.join(work, "원본"); out = os.path.join(base, "결과")
qf = os.path.join(src, "문항.typ"); qt = open(qf, encoding="utf-8").read()
m = re.search(r'#let V = "v(\d+)"', qt)
if not m: sys.exit('문항.typ에 #let V = "v1" 줄이 없습니다')
ver = int(m.group(1))
meta = json.load(open(os.path.join(src, "print.json"), encoding="utf-8")) if os.path.exists(os.path.join(src, "print.json")) else {}
name = meta.get("name") or (re.search(r'#let NAME = "([^"]+)"', qt) or [None, os.path.basename(base)])[1]
if a.next:
    old, ver = f"v{ver}", ver + 1
    new = f"v{ver}"
    open(qf, "w", encoding="utf-8").write(qt.replace(f'#let V = "{old}"', f'#let V = "{new}"', 1))
    for f in glob.glob(os.path.join(work, "그림", f"{name}_{old}_*")):   # 그림 이름에 판이 들어가므로 새 판 이름으로 복사(원본 그림 그대로)
        shutil.copy(f, f.replace(f"_{old}_", f"_{new}_"))
V = f"v{ver}"; N = f"{name}_시험지_{V}"
os.makedirs(out, exist_ok=True); os.makedirs(os.path.join(work, "확인"), exist_ok=True)
def T(*args):
    r = subprocess.run(["typst", "compile", "--root", work, "--font-path", FONTS, *args], cwd=src, capture_output=True, text=True)
    msg = "\n".join(l for l in r.stderr.splitlines() if "unknown font family" not in l)
    if r.returncode: print(msg, file=sys.stderr); sys.exit(f"실패: {args[0]}")
    if "warning" in msg: print(msg, file=sys.stderr)
for doc, tail in (("책.typ", ""), ("해설.typ", "_해설"), ("검토용지.typ", "_검토용지")):
    T(doc, os.path.join(out, f"{N}{tail}.pdf")); print("만듦:", os.path.join(out, f"{N}{tail}.pdf"))
if not a.no_png:
    for doc, k, ppi in (("책.typ", "시험지", "120"), ("해설.typ", "해설", "100"), ("검토용지.typ", "검토용지", "100")):
        T("--ppi", ppi, doc, os.path.join(work, "확인", f"{V}_{k}_{{p}}.png"))
r = subprocess.run([sys.executable, os.path.join(HERE, "exam_table.py"), base, "--name", name, "--v", V])
if r.returncode: sys.exit("문항표를 만들지 못했습니다(openpyxl이 없으면 check_env.py --install)")
