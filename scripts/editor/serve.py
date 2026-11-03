"""print 편집기: 왼쪽 원본(Typst) · 오른쪽 조판된 쪽을 한 화면에. 파일이 바뀌면(사람이 저장하든 AI가 고치든) 바로 다시 조판한다.
사용: python3 serve.py <자료폴더>/원본 [--port 8950]
      → 브라우저에서 http://localhost:8950 (Claude 앱이면 오른쪽 브라우저 칸에 띄운다)
필요: typst. 파이썬 표준 라이브러리만 쓴다. 이 컴퓨터 안에서만 열린다(127.0.0.1).
"""
import argparse, hashlib, json, os, re, shutil, socket, subprocess, sys, threading, time, urllib.parse, uuid
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
PARENT = os.path.dirname(ROOT)
EXAM = os.path.basename(PARENT) == "작업" and os.path.exists(os.path.join(ROOT, "문항.typ"))   # 시험지 세트
TROOT = PARENT if EXAM else ROOT
CACHE = os.path.join(os.path.expanduser("~/.cache/print/preview"), hashlib.md5(ROOT.encode()).hexdigest()[:10])
os.makedirs(CACHE, exist_ok=True)

# 새 폴더 구조(자료폴더/작업/원본)면 자료 폴더 이름을 책 이름으로
BOOK = os.path.basename(os.path.dirname(os.path.dirname(ROOT))) if os.path.basename(os.path.dirname(ROOT)) == "작업" else (os.path.basename(os.path.dirname(ROOT)) or os.path.basename(ROOT))
S = {"qparts": [], "qpos": [], "ver": 0, "target": "책.typ", "pages": 0, "error": None, "ms": 0, "busy": False, "changed": {}, "files_ver": 0}
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

def entries(text):
    """content.typ의 `#let questions = (` 안 맨 위 항목들의 (시작 글자, 끝 글자). [] 글 안의 괄호와 "" 문자열은 세지 않는다."""
    m = re.search(r"#let\s+questions\s*=\s*\(", text)
    if not m: return []
    i, out, stack, start = m.end(), [], ["("], None
    while i < len(text) and stack:
        c = text[i]
        if stack[-1] == "[":                       # 글(markup): [ ]만 센다
            if c == "\\": i += 2; continue
            if c == "[": stack.append("[")
            elif c == "]": stack.pop()
        elif c == '"':                              # 문자열
            j = i + 1
            while j < len(text) and text[j] != '"': j += 2 if text[j] == "\\" else 1
            i = j
        elif c == "/" and text.startswith("//", i):   # 줄 주석
            i = text.find("\n", i); i = len(text) if i < 0 else i; continue
        elif c in "([{":
            if c == "(" and len(stack) == 1: start = i
            stack.append(c)
        elif c in ")]}":
            stack.pop()
            if len(stack) == 1 and c == ")" and start is not None: out.append((start, i + 1)); start = None
        i += 1
    return out

def qmap():
    """문항 번호 → 파일 · 줄 범위 · 표시 · 첫 글. 번호는 파트 순서대로 이어진다(order.typ와 같음)."""
    parts = sorted((d for d in os.listdir(ROOT) if re.fullmatch(r"파트\d+", d) and os.path.exists(os.path.join(ROOT, d, "content.typ"))), key=lambda d: int(d[2:]))
    rels = ["문항.typ"] if EXAM else [f"{d}/content.typ" for d in parts]
    out, n = [], 0
    for rel in rels:
        text = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        for a, b in entries(text):
            n += 1; body = text[a:b]
            tag = (re.search(r'(?:tag|src):\s*"([^"]*)"', body) or [None, ""])[1]
            lm = re.search(r"lead:\s*(?:body\()?\[(.*?)\]", body, re.S)
            lead = re.sub(r"\s+", " ", re.sub(r"#\w+(\.\w+)*(\[[^\]]*\])?|[\[\]()\"\\]", " ", lm.group(1) if lm else "")).strip()
            keys = [(m.group(1), m.start(1)) for m in re.finditer(r"(?m)^\s*(lead|material|after|ask|bogi|choices|explain|answer|no|orig|how|source|form|figs|cols|points)\s*:", body)]
            pl = {}
            for i, (k, at) in enumerate(keys):
                if k in ("lead", "material", "after", "ask", "bogi", "choices"):
                    end = keys[i + 1][1] if i + 1 < len(keys) else len(body)
                    l0 = text.count("\n", 0, a + at) + 1
                    l1 = max(l0, text.count("\n", 0, a + end) + (0 if i + 1 == len(keys) else 0))   # 다음 키 줄 바로 앞까지
                    if i + 1 < len(keys): l1 = max(l0, text.count("\n", 0, a + keys[i + 1][1]))
                    pl[k] = [l0, l1]
            out.append({"n": n, "file": rel, "a": a, "b": b, "parts": pl, "line0": text.count("\n", 0, a) + 1, "line1": text.count("\n", 0, b) + 1, "tag": tag, "text": lead[:40]})
    return out

def query(target, label):
    r = subprocess.run(["typst", "query", "--root", TROOT, "--font-path", FONTS, target, label, "--field", "value"], cwd=ROOT, capture_output=True, text=True)
    try: return json.loads(r.stdout) if r.returncode == 0 else []
    except ValueError: return []

def qpos(target):
    """조판한 문서에서 문항마다 쪽 · 위치(pt). 서식에 <qpos> 표시가 없으면 빈 목록."""
    r = subprocess.run(["typst", "query", "--root", TROOT, "--font-path", FONTS, target, "<qpos>", "--field", "value"], cwd=ROOT, capture_output=True, text=True)
    try: return json.loads(r.stdout) if r.returncode == 0 else []
    except ValueError: return []

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
    r = subprocess.run(["typst", "compile", "--root", TROOT, "--font-path", FONTS, target, os.path.join(tmp, "p-{p}.svg")],
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
            S["qpos"] = qpos(target)
            S["qparts"] = query(target, "<qpart>")
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

JOBS = {}
REVIEW = "정답이 하나뿐인가 · 성취기준과 맞는가 · 교육과정 밖 개념은 없는가 · 자료(그림 · 표 · 그래프)와 맞는가 · 발문과 조건이 분명한가 · 선지가 고르게 매력적인가 · 오탈자 · 표기 · 예상 난이도"

def ai_prompt(mode, items, instruction):
    blocks = "\n\n".join(f"### {it['n']}번 ({it['file']} {it['line0']}–{it['line1']}줄)\n```typst\n{it['src']}\n```" for it in items)
    head = ("너는 고등학교 시험 문항 검토자야. 아래 문항들을 하나씩 검토해. 파일은 읽기만 하고 아무것도 고치지 마.\n"
            f"기준: {REVIEW}.\n"
            "답은 JSON 하나만: {\"items\": [{\"n\": 번호, \"verdict\": \"좋음\"|\"고칠 점 있음\"|\"문제 있음\", \"notes\": [\"한 문장씩\"], \"answer_check\": \"정답을 직접 풀어 본 결과 한 줄\"}]}")
    if mode == "edit":
        head = ("너는 고등학교 시험 문항 출제자야. 아래 문항들을 요청대로 고쳐. 파일은 직접 고치지 말고 고친 항목을 답으로만 줘.\n"
                f"요청: {instruction or '더 좋은 문항으로 다듬어 줘'}\n"
                "규칙: 각 항목은 같은 Typst 형식(괄호로 시작해 괄호로 끝나는 한 항목, 키 이름 그대로)을 지킨다. 정답 · 해설도 고친 내용에 맞게 다시 풀어 맞춘다. 그림 파일(material)은 바꾸지 말고 그대로 둔다. 교육과정 밖 개념을 넣지 않는다.\n"
                "답은 JSON 하나만: {\"items\": [{\"n\": 번호, \"src\": \"고친 항목 전체(Typst)\", \"why\": \"무엇을 왜 바꿨는지 한두 문장\"}]}")
    return head + "\n\n" + blocks

def run_ai(jid):
    j = JOBS[jid]
    prompt = ai_prompt(j["mode"], j["items"], j["instruction"])
    try:
        if j["provider"] == "claude":
            cmd = ["claude", "-p", "--output-format", "text"]
        else:
            out = os.path.join(CACHE, f"ai-{jid}.md")
            cmd = ["codex", "exec", "--skip-git-repo-check", "-s", "read-only", "-o", out, "-"]
        r = subprocess.run(cmd, input=prompt, cwd=ROOT, capture_output=True, text=True, timeout=600)
        text = r.stdout if j["provider"] == "claude" else (open(out, encoding="utf-8").read() if os.path.exists(out) else r.stdout)
        if re.search(r"not logged in|/login|please log ?in|unauthori", (r.stderr or "") + (text or ""), re.I):
            who = "Claude Code" if j["provider"] == "claude" else "Codex"
            raise ValueError(f"{who}에 로그인이 안 되어 있습니다. 터미널에서 {'claude' if j['provider'] == 'claude' else 'codex'}를 한 번 실행해 로그인한 뒤 다시 누르세요. 그동안은 다른 AI를 고르면 됩니다.")
        m = re.search(r"\{.*\}", text, re.S)
        if not m: raise ValueError((r.stderr or text).strip()[-600:] or "AI 답을 읽지 못했습니다")
        res = json.loads(m.group(0))
        for it in res.get("items", []):
            src = next((x for x in j["items"] if x["n"] == it.get("n")), None)
            if src: it["before"] = src["src"]
        j["result"], j["status"] = res, "done"
    except subprocess.TimeoutExpired:
        j["status"], j["error"] = "error", "10분 안에 답이 오지 않았습니다"
    except Exception as e:
        j["status"], j["error"] = "error", str(e)[:800]

def apply_edits(jid, ns):
    """수정안을 원본에 넣는다. 고치기 전 파일은 .backup/에 남긴다. AI가 본 뒤 그 문항이 바뀌었으면 넣지 않는다."""
    j = JOBS[jid]; done, skipped = [], []
    stamp = time.strftime("%Y%m%d-%H%M%S")
    for it in sorted((x for x in j["result"].get("items", []) if x.get("n") in ns and x.get("src")), key=lambda x: -x["n"]):
        orig = next(x for x in j["items"] if x["n"] == it["n"])
        path = inside(orig["file"]); text = open(path, encoding="utf-8").read()
        k = text.find(orig["src"])
        if k < 0: skipped.append(it["n"]); continue
        bdir = os.path.join(ROOT, ".backup"); os.makedirs(bdir, exist_ok=True)
        shutil.copy(path, os.path.join(bdir, f"{stamp}_{orig['file'].replace('/', '_')}"))
        new = it["src"].strip()
        with open(path, "w", encoding="utf-8") as f: f.write(text[:k] + new + text[k + len(orig["src"]):])
        done.append(it["n"])
    return done, skipped

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
                    return self.send(200, {k: S[k] for k in ("ver", "target", "pages", "error", "ms", "busy", "files_ver")} | {"book": BOOK, "root": ROOT})
            if u.path == "/api/questions":
                with lock: pos, parts = list(S["qpos"]), list(S["qparts"])
                return self.send(200, {"questions": qmap(), "pos": pos, "parts": parts, "exam": EXAM, "ai": {k: bool(shutil.which(k)) for k in ("claude", "codex")}})
            if u.path == "/api/ai/job":
                j = JOBS.get(q["id"][0])
                if not j: return self.send(404, {"error": "작업 없음"})
                return self.send(200, {k: j[k] for k in ("status", "result", "error", "provider", "mode")})
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
            if u.path == "/api/ai/run":
                req = json.loads(body or b"{}")
                if req.get("provider") not in ("claude", "codex") or not shutil.which(req["provider"]): raise ValueError("이 컴퓨터에 그 AI 프로그램이 없습니다")
                qs = {x["n"]: x for x in qmap()}
                items = []
                for n in req.get("ns", [])[:20]:
                    x = qs.get(n)
                    if not x: continue
                    t = open(inside(x["file"]), encoding="utf-8").read()
                    items.append({**x, "src": t[x["a"]:x["b"]]})
                if not items: raise ValueError("고른 문항이 없습니다")
                jid = uuid.uuid4().hex[:10]
                JOBS[jid] = {"status": "running", "result": None, "error": None, "provider": req["provider"], "mode": "edit" if req.get("mode") == "edit" else "review", "instruction": (req.get("instruction") or "")[:1000], "items": items}
                threading.Thread(target=run_ai, args=(jid,), daemon=True).start()
                return self.send(200, {"id": jid})
            if u.path == "/api/ai/apply":
                req = json.loads(body or b"{}")
                if req.get("id") not in JOBS: raise ValueError("작업 없음")
                done, skipped = apply_edits(req["id"], set(req.get("ns", [])))
                return self.send(200, {"done": done, "skipped": skipped})
            if u.path == "/api/excel":   # 「엑셀 저장」: 지금 판의 문항표(시험지 세트)
                if not EXAM: raise ValueError("문항표는 시험지 세트에서만 만듭니다")
                qt = open(os.path.join(ROOT, "문항.typ"), encoding="utf-8").read()
                v = (re.search(r'#let V = "(v\d+)"', qt) or [None, "v1"])[1]
                meta = json.load(open(os.path.join(ROOT, "print.json"), encoding="utf-8")) if os.path.exists(os.path.join(ROOT, "print.json")) else {}
                name = meta.get("name") or (re.search(r'#let NAME = "([^"]+)"', qt) or [None, "시험지"])[1]
                r = subprocess.run([sys.executable, os.path.join(HERE, "..", "exam_table.py"), os.path.dirname(PARENT), "--name", name, "--v", v], capture_output=True, text=True)
                made = [l[4:].split(" (")[0].strip() for l in r.stdout.splitlines() if l.startswith("만듦:")]
                if r.returncode or not made: raise ValueError((r.stderr or r.stdout).strip()[-800:] or "엑셀을 만들지 못했습니다")
                return self.send(200, {"files": [os.path.basename(x) for x in made]})
            if u.path == "/api/export":   # 「PDF 저장」: build.py --next로 새 버전을 결과/에
                cmd = [os.path.join(HERE, "..", "exam_build.py"), os.path.dirname(PARENT), "--next", "--no-png"] if EXAM else [os.path.join(HERE, "..", "build.py"), ROOT, "--next"]
                r = subprocess.run([sys.executable, *cmd], capture_output=True, text=True)
                made = [l[4:].strip() for l in r.stdout.splitlines() if l.startswith("만듦:")]
                if r.returncode or not made: raise ValueError((r.stderr or r.stdout).strip()[-800:] or "PDF를 만들지 못했습니다")
                return self.send(200, {"files": [os.path.basename(x) for x in made], "dir": os.path.dirname(made[0])})
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
