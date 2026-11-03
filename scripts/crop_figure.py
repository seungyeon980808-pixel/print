"""원본 그림을 잘라 낸다(그리지 않는다). 맥 · 윈도우 모두 pymupdf만 쓴다.
사용: python3 crop_figure.py 입력.png 출력.png 왼 위 오 아래              (0~1 비율)
      python3 crop_figure.py 책.pdf:쪽번호 출력.png 왼 위 오 아래          (PDF 쪽을 300dpi로 그려서 자름)
      --gray  회색조로(검토 용지의 참고원본/회색/용)
그림 이름 규칙: 작업/그림/<날짜_과목>_<판>_<문항번호2자리>_<순번>.png · 참고 원본: 작업/참고원본/원본_<번호>_<자료>_<쪽 · 번호>.png
"""
import argparse, os, pymupdf

ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("dst"); ap.add_argument("box", nargs=4, type=float); ap.add_argument("--gray", action="store_true")
a = ap.parse_args()
if ".pdf:" in a.src.lower():
    f, n = a.src.rsplit(":", 1)
    pm = pymupdf.open(f)[int(n) - 1].get_pixmap(dpi=300)
else:
    pm = pymupdf.Pixmap(a.src)
if pm.alpha: pm = pymupdf.Pixmap(pm, 0)
W, H = pm.width, pm.height
x0, y0, x1, y1 = int(a.box[0] * W), int(a.box[1] * H), int(a.box[2] * W), int(a.box[3] * H)
r = pymupdf.IRect(max(0, x0), max(0, y0), min(W, x1), min(H, y1))
out = pymupdf.Pixmap(pm.colorspace, r, False); out.copy(pm, r); out.set_origin(0, 0)
if a.gray and out.colorspace.n != 1: out = pymupdf.Pixmap(pymupdf.csGRAY, out)
os.makedirs(os.path.dirname(os.path.abspath(a.dst)), exist_ok=True)
out.save(a.dst); print("만듦:", a.dst, f"{r.width}×{r.height}")
