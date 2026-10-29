"""print 편집기: 왼쪽 원본(Typst) · 오른쪽 조판된 쪽을 한 화면에. 파일이 바뀌면(사람이 저장하든 AI가 고치든) 바로 다시 조판한다.
사용: python3 serve.py <자료폴더>/원본 [--port 8950]
      → 브라우저에서 http://localhost:8950 (Claude 앱이면 오른쪽 브라우저 칸에 띄운다)
필요: typst. 파이썬 표준 라이브러리만 쓴다. 이 컴퓨터 안에서만 열린다(127.0.0.1).
"""
import argparse, hashlib, json, os, re, socket, subprocess, sys, threading, time, urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.abspath(os.path.join(HERE, "..", "..", "fonts"))
EDITABLE = (".typ", ".md", ".csv", ".txt")
WATCH = EDITABLE + (".png", ".jpg", ".jpeg", ".svg", ".webp")

ap = argparse.ArgumentParser()
ap.add_argument("dir")
ap.add_argument("--port", type=int, default=8950)
a = ap.parse_args()
ROOT = os.path.abspath(a.dir)
if not os.path.exists(os.path.join(ROOT, "책.typ")):
    sys.exit(f"책.typ가 없습니다: {ROOT}\n원본 폴더(new_book.py로 만든 폴더)를 주세요.")
CACHE = os.path.join(os.path.expanduser("~/.cache/print/preview"), hashlib.md5(ROOT.encode()).hexdigest()[:10])
os.makedirs(CACHE, exist_ok=True)

S = {"ver": 0, "target": "책.typ", "pages": 0, "error": None, "ms": 0, "busy": False, "changed": {}, "files_ver": 0}
lock = threading.Lock()

def inside(rel):
    p = os.path.abspath(os.path.join(ROOT, rel))
    if not (p == ROOT or p.startswith(ROOT + os.sep)):
        raise ValueError("원본 폴더 밖")
    return p

def files():
    out = []
    for d, ds, fs in os.walk(ROOT):
        ds[:] = sorted(x for x in ds if not x.startswith(".") and x not in ("출력", "out"))
        for f in fs:
            if f.endswith(EDITABLE) and not f.startswith("."):
                out.append(os.path.relpath(os.path.join(d, f), ROOT))
    key = lambda p: [(int(t) if t.isdigit() else t) for t in re.split(r"(\d+)", p)]
    return sorted(out, key=key)

def snapshot():
    snap = {}
    for d, ds, fs in os.walk(ROOT):
        ds[:] = [x for x in ds if not x.startswith(".") and x not in ("출력", "out")]
        for f in fs:
            if f.endswith(WATCH):
                p = os.path.join(d, f)
                try: snap[os.path.relpath(p, ROOT)] = os.stat(p).st_mtime_ns
                except OSError: pass
    return snap

def parse_error(err):
    # typst 오류: "error: …" 다음 줄들에 "┌─ 파일:줄:칸"
    m = re.search(r"error: (.+?)\n.*?┌─ ([^\n]+?):(\d+):(\d+)", err, re.S)
    if m:
        return {"message": m.group(1).strip(), "file": m.group(2).strip().lstrip("/"), "line": int(m.group(3)), "text": err}
    return {"message": err.strip().splitlines()[0] if err.strip() else "조판 실패", "file": None, "line": None, "text": err}

def compile_once():
    with lock:
        target, S["busy"] = S["target"], True
    t0 = time.time()
    tmp = os.path.join(CACHE, "next")
    os.makedirs(tmp, exist_ok=True)
    for f in os.listdir(tmp):
        os.remove(os.path.join(tmp, f))
    r = subprocess.run(["typst", "compile", "--root", ROOT, "--font-path", FONTS, target, os.path.join(tmp, "p-{p}.svg")],
                       cwd=ROOT, capture_output=True, text=True)
    err = "\n".join(l for l in r.stderr.splitlines() if "unknown font family" not in l)
    with lock:
        S["busy"], S["ms"] = False, int((time.time() - t0) * 1000)
        if r.returncode:
            S["error"] = parse_error(err)
        else:
            cur = os.path.join(CACHE, "cur")
            os.makedirs(cur, exist_ok=True)
            for f in os.listdir(cur):
                os.remove(os.path.join(cur, f))
            n = 0
            for f in os.listdir(tmp):
                os.replace(os.path.join(tmp, f), os.path.join(cur, f)); n += 1
            S["pages"], S["error"] = n, None
        S["ver"] += 1

def watcher():
    last = None
    while True:
        snap = snapshot()
        with lock:
            force = S.pop("force", False)
        if snap != last or force:
            if last is not None:
                changed = {k: v for k, v in snap.items() if last.get(k) != v}
                with lock:
                    S["changed"].update(changed); S["files_ver"] += 1
            last = snap
            compile_once()
        time.sleep(0.35)

class H(BaseHTTPRequestHandler):
    def log_message(self, *x): pass
    def send(self, code, body, ctype="application/json; charset=utf-8", extra=None):
        b = body if isinstance(body, bytes) else (json.dumps(body, ensure_ascii=False) if not isinstance(body, str) else body).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items(): self.send_header(k, v)
        self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        u = urllib.parse.urlparse(self.path); q = urllib.parse.parse_qs(u.query)
        try:
            if u.path == "/":
                return self.send(200, open(os.path.join(HERE, "index.html"), encoding="utf-8").read(), "text/html; charset=utf-8")
            if u.path == "/api/state":
                with lock:
                    return self.send(200, {k: S[k] for k in ("ver", "target", "pages", "error", "ms", "busy", "files_ver")} | {"book": os.path.basename(os.path.dirname(ROOT)) or os.path.basename(ROOT), "root": ROOT})
            if u.path == "/api/files":
                return self.send(200, files())
            if u.path == "/api/file":
                p = inside(q["p"][0])
                return self.send(200, {"text": open(p, encoding="utf-8").read(), "mtime": os.stat(p).st_mtime_ns})
            m = re.fullmatch(r"/page/(\d+)\.svg", u.path)
            if m:
                return self.send(200, open(os.path.join(CACHE, "cur", f"p-{m.group(1)}.svg"), "rb").read(), "image/svg+xml")
            return self.send(404, {"error": "없음"})
        except FileNotFoundError:
            return self.send(404, {"error": "파일 없음"})
        except Exception as e:
            return self.send(400, {"error": str(e)})
    def do_POST(self):
        u = urllib.parse.urlparse(self.path); q = urllib.parse.parse_qs(u.query)
        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        try:
            if u.path == "/api/file":
                rel = q["p"][0]
                if not rel.endswith(EDITABLE): raise ValueError("고칠 수 없는 파일")
                p = inside(rel)
                with open(p, "w", encoding="utf-8") as f: f.write(body.decode("utf-8"))
                return self.send(200, {"mtime": os.stat(p).st_mtime_ns})
            if u.path == "/api/target":
                rel = q["p"][0]; inside(rel)
                with lock: S["target"] = rel; S["force"] = True
                return self.send(200, {"ok": True})
            return self.send(404, {"error": "없음"})
        except Exception as e:
            return self.send(400, {"error": str(e)})

port = a.port
while True:
    with socket.socket() as s:
        if s.connect_ex(("127.0.0.1", port)): break
    port += 1
threading.Thread(target=watcher, daemon=True).start()
print(f"print 편집기: http://localhost:{port}  (원본: {ROOT})", flush=True)
ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
