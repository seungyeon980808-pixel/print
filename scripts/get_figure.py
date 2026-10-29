"""평가원 기출 문항을 원본 시험지 PDF에서 고해상도 그림으로 뽑는다(교재의 파트N/img/에 넣을 그림).
사용: python3 get_figure.py e1_2011_09_13 --out 파트1/img            → e1_2011_09_13.png (문항 전체)
      python3 get_figure.py e1_2011_09_13 --out 파트1/img --clip 0.05,0.30,0.95,0.70 --name e1_2011_09_13_1
        --clip: 문항 그림 안에서 자를 범위(왼쪽,위,오른쪽,아래 / 0~1 비율). 먼저 전체를 뽑아 눈으로 보고 그림 부분만 다시 뽑는다.
원본 PDF는 5E 공개 게이트웨이에서 받아 ~/.cache/print/pdf/에 둔다(한 번만). 받지 못하면 기출 탐색기의 문항 카드(WebP)를 대신 받는다.
필요: pymupdf (pip install pymupdf)
"""
import argparse, gzip, json, os, sys, time, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "..", "data")
PUBLIC = "https://5e-google-drive-gateway.5e-desktop.workers.dev/v1/google-drive/folders/1N46Woe4wIXs-PoUpVf0Uu4hPkSIUBqgX/public/"
EXPANSION = "https://5e-google-drive-gateway.5e-desktop.workers.dev/v1/google-drive/folders/1ckc6lPTmGobFNf8Zv0zMuwR5Gg3qykGo/public/"
CACHE = os.path.expanduser("~/.cache/print/pdf")

ap = argparse.ArgumentParser()
ap.add_argument("id")
ap.add_argument("--out", default=".")
ap.add_argument("--name", default="")
ap.add_argument("--clip", default="")
ap.add_argument("--dpi", type=int, default=300)
a = ap.parse_args()

db = json.loads(gzip.open(os.path.join(DATA, "kice-questions.json.gz")).read())
q = next((x for x in db["items"] if x["id"] == a.id), None)
if not q:
    sys.exit(f"없는 문항 번호: {a.id} (find_items.py로 찾은 id를 쓰세요)")
paths = json.load(open(os.path.join(DATA, "kice-files.json"), encoding="utf-8"))
os.makedirs(a.out, exist_ok=True)
name = (a.name or a.id) + ".png"

def link(path):
    seg = path.split("/")
    if seg[:2] == ["기출문제", "기출확장_국영수사탐"]:
        return EXPANSION + "/".join(urllib.parse.quote(s) for s in seg[2:])
    return PUBLIC + "/".join(urllib.parse.quote(s) for s in seg)

def fetch(url, tries=4):
    for i in range(tries):
        try:
            req = urllib.request.Request(url + (f"?retry={time.time()}" if i else ""), headers={"User-Agent": "print-skill/1.0"})
            with urllib.request.urlopen(req, timeout=40) as r:
                return r.read()
        except Exception as e:
            err = e
    raise err

pdf = os.path.join(CACHE, q["pdf"] or "")
try:
    if not os.path.exists(pdf):
        os.makedirs(CACHE, exist_ok=True)
        data = fetch(link(paths[q["pdf"]]))
        open(pdf, "wb").write(data)
    import pymupdf
    page = pymupdf.open(pdf)[q["page"] - 1]
    x0, y0, x1, y1 = q["box"]
    r = pymupdf.Rect(x0, y0, x1, y1)
    if a.clip:
        f = [float(v) for v in a.clip.split(",")]
        r = pymupdf.Rect(x0 + (x1 - x0) * f[0], y0 + (y1 - y0) * f[1], x0 + (x1 - x0) * f[2], y0 + (y1 - y0) * f[3])
    page.get_pixmap(clip=r, dpi=a.dpi).save(os.path.join(a.out, name))
    print("만듦:", os.path.join(a.out, name), f"({q['title']}, 원본 PDF {a.dpi}dpi)")
except Exception as e:
    if not q.get("card"):
        sys.exit(f"원본 PDF를 받지 못했고 문항 카드도 없습니다: {e}\n사용자에게 시험지 PDF를 자료 폴더에 넣어 달라고 하세요.")
    webp = os.path.join(a.out, (a.name or a.id) + ".webp")
    open(webp, "wb").write(fetch(db["cardUrl"].replace("{id}", a.id)))
    print("만듦(대신 받은 문항 카드):", webp, f"원본 PDF 실패: {e}")
