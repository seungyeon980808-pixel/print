"""원본 폴더를 PDF로 뽑는다. 글꼴은 저장소의 fonts/(Pretendard)와 컴퓨터에 깔린 글꼴을 함께 쓴다.
사용: python3 build.py <자료폴더>/작업/원본 [--name 20261103_역학과에너지_시험지] [--next] [--parts] [--png 쪽번호]
  원본이 작업/원본이면(새 폴더 구조):
    한 권:    <자료폴더>/결과/<이름>_v<버전>.pdf   (해설 따로: _해설.pdf)
    --parts:  <자료폴더>/작업/파트별/ · --png: <자료폴더>/작업/확인/
  그 밖(옛 구조): <자료폴더>/출력/<이름>.pdf
  이름: --name, 없으면 원본/print.json의 "name", 없으면 폴더 이름.
  버전: 결과/에 같은 이름의 가장 높은 v를 덮어쓴다(처음이면 v1). --next면 새 버전(v+1)으로 만든다 — 사용자가 고친 뒤에는 늘 --next.
"""
import argparse, glob, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.abspath(os.path.join(HERE, "..", "fonts"))

ap = argparse.ArgumentParser()
ap.add_argument("dir")
ap.add_argument("--name", default="")
ap.add_argument("--next", action="store_true", help="새 버전으로(이전 판은 남김)")
ap.add_argument("--parts", action="store_true")
ap.add_argument("--png", default="", help="쉼표로 쪽 번호(표지 포함 PDF 쪽 순서)")
a = ap.parse_args()
root = os.path.abspath(a.dir)
import json, re
parent = os.path.dirname(root)
new_layout = os.path.basename(parent) == "작업"
out = os.path.join(os.path.dirname(parent), "결과") if new_layout else os.path.join(parent, "출력")
side = parent if new_layout else out          # 파트별 · 확인 그림은 작업/에(결과/에는 완성본만)
meta = {}
try: meta = json.load(open(os.path.join(root, "print.json"), encoding="utf-8"))
except (OSError, ValueError): pass
name = a.name or meta.get("name") or os.path.basename(os.path.dirname(parent if new_layout else root)) or "교재"
if new_layout:
    name = re.sub(r"_v\d+$", "", name)
    vs = [int(m.group(1)) for f in (os.listdir(out) if os.path.isdir(out) else []) for m in [re.fullmatch(re.escape(name) + r"_v(\d+)\.pdf", f)] if m]
    ver = (max(vs) + 1 if a.next else max(vs)) if vs else 1
    name = f"{name}_v{ver}"

def typst(src, dst, *extra):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    cmd = ["typst", "compile", "--root", root, "--font-path", FONTS, *extra, src, dst]
    r = subprocess.run(cmd, cwd=root, capture_output=True, text=True)
    msg = "\n".join(l for l in r.stderr.splitlines() if "unknown font family" not in l)
    if r.returncode:
        print(msg, file=sys.stderr); sys.exit(f"실패: {os.path.relpath(src, root)}")
    if "warning" in msg:
        print(msg, file=sys.stderr)
    print("만듦:", dst)

typst("책.typ", os.path.join(out, name + ".pdf"))
try:   # 칸에 안 들어가 줄인 문항이 있으면 쪽 번호를 알려 준다(최종본에 남기지 말 것)
    import pymupdf
    bad = [i + 1 for i, pg in enumerate(pymupdf.open(os.path.join(out, name + ".pdf"))) if "칸 넘침" in pg.get_text()]
    if bad:
        print(f"주의: 칸 넘침 {len(bad)}쪽 — PDF 쪽 {', '.join(map(str, bad))}. 그림을 줄이거나 문항을 다른 칸으로 옮기세요.", file=sys.stderr)
except ImportError:
    pass
# 정답을 교사용으로 따로 두는 책이면 교사용 PDF도
if os.path.exists(os.path.join(root, "교사용.typ")) and 'answers: "teacher"' in open(os.path.join(root, "brand.typ"), encoding="utf-8").read():
    typst("교사용.typ", os.path.join(out, name + ("_해설.pdf" if new_layout else "_교사용.pdf")))
if a.parts:
    for d in sorted(glob.glob(os.path.join(root, "파트*")), key=lambda p: int("".join(c for c in os.path.basename(p) if c.isdigit()) or 0)):
        for f in ("개념편.typ", "문항편.typ"):
            if os.path.exists(os.path.join(d, f)):
                typst(os.path.join(d, f), os.path.join(side, "파트별", f"{os.path.basename(d)}_{f[:-4]}.pdf"))
for p in [x for x in a.png.split(",") if x.strip()]:
    typst("책.typ", os.path.join(side, "확인", f"p{p.strip()}.png"), "--pages", p.strip(), "--ppi", "110")
