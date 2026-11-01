"""원본 폴더를 PDF로 뽑는다. 글꼴은 저장소의 fonts/(Pretendard)와 컴퓨터에 깔린 글꼴을 함께 쓴다.
사용: python3 build.py <자료폴더>/원본 [--name 별과우주] [--parts] [--png 쪽번호]
  한 권:     <자료폴더>/출력/<이름>.pdf
  --parts:  <자료폴더>/출력/파트별/파트N_개념편.pdf · 파트N_문항편.pdf
  --png 3:  <자료폴더>/출력/확인/p3.png (눈으로 확인할 쪽만 그림으로)
"""
import argparse, glob, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.abspath(os.path.join(HERE, "..", "fonts"))

ap = argparse.ArgumentParser()
ap.add_argument("dir")
ap.add_argument("--name", default="")
ap.add_argument("--parts", action="store_true")
ap.add_argument("--png", default="", help="쉼표로 쪽 번호(표지 포함 PDF 쪽 순서)")
a = ap.parse_args()
root = os.path.abspath(a.dir)
out = os.path.join(os.path.dirname(root), "출력")
name = a.name or os.path.basename(os.path.dirname(root)) or "교재"

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
    typst("교사용.typ", os.path.join(out, name + "_교사용.pdf"))
if a.parts:
    for d in sorted(glob.glob(os.path.join(root, "파트*")), key=lambda p: int("".join(c for c in os.path.basename(p) if c.isdigit()) or 0)):
        for f in ("개념편.typ", "문항편.typ"):
            if os.path.exists(os.path.join(d, f)):
                typst(os.path.join(d, f), os.path.join(out, "파트별", f"{os.path.basename(d)}_{f[:-4]}.pdf"))
for p in [x for x in a.png.split(",") if x.strip()]:
    typst("책.typ", os.path.join(out, "확인", f"p{p.strip()}.png"), "--pages", p.strip(), "--ppi", "110")
