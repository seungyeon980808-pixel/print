"""준비물 점검: Typst · 글꼴 · pymupdf가 있는지 보고, 없으면 이 컴퓨터에 맞는 설치 명령을 알려 준다.
사용: python3 check_env.py            (점검만)
      python3 check_env.py --install  (맥: Homebrew로, 윈도우: winget·pip으로 빠진 것만 설치)
"""
import argparse, os, platform, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.abspath(os.path.join(HERE, "..", "fonts"))
OS = {"Darwin": "mac", "Windows": "win"}.get(platform.system(), "linux")
ap = argparse.ArgumentParser()
ap.add_argument("--install", action="store_true")
a = ap.parse_args()

PY = "py -m pip" if OS == "win" else f"{os.path.basename(sys.executable)} -m pip"
FIX = {
    "typst": {"mac": "brew install typst", "win": "winget install --id Typst.Typst -e", "linux": "https://github.com/typst/typst/releases 에서 받기"},
    "pymupdf": {"mac": f"{PY} install --user pymupdf", "win": f"{PY} install --user pymupdf", "linux": f"{PY} install --user pymupdf"},
    "serif": {"mac": "brew install --cask font-ko-pub-batang",
              "win": "KoPub World 바탕체(무료)를 내려받아 설치 — 한국출판인회의 「KoPub 서체」 페이지. 없으면 Noto Serif KR로 대신 씀",
              "linux": "KoPub World 바탕체 또는 Noto Serif KR 설치"},
}
problems = []

def ok(name, good, note=""):
    print(("  ✓ " if good else "  ✗ ") + name + (f"  ({note})" if note else ""))
    if not good: problems.append(name)

print(f"print 준비물 점검 · {OS}")
typst = shutil.which("typst")
ver = subprocess.run(["typst", "--version"], capture_output=True, text=True).stdout.strip() if typst else ""
good = False
if ver:
    try: good = tuple(int(x) for x in ver.split()[1].split(".")[:2]) >= (0, 13)
    except Exception: good = True
ok("typst", good, ver or "없음 · 0.13 이상 필요")
try:
    import pymupdf  # noqa
    ok("pymupdf", True, "교과서·기출 PDF 읽기")
except ImportError:
    ok("pymupdf", False, "교과서·기출 PDF 읽기")
fams = subprocess.run(["typst", "fonts", "--font-path", FONTS], capture_output=True, text=True).stdout if typst else ""
ok("Pretendard", "Pretendard" in fams, "저장소 fonts/에 들어 있음")
serif = "KoPub Batang" in fams
ok("serif", serif or "Noto Serif KR" in fams, "KoPub 바탕" if serif else ("KoPub 바탕 없음 → Noto Serif KR로 대신" if "Noto Serif KR" in fams else "본문 명조 글꼴 없음"))
if "serif" not in problems and not serif:
    print("    본문 글꼴을 「별과 우주」와 똑같이 하려면:", FIX["serif"][OS])
print(f"  · git {'있음' if shutil.which('git') else '없음(스킬 받기에 필요)'}")

if not problems:
    print("준비 끝. 바로 시작할 수 있습니다."); sys.exit(0)
print("\n빠진 것과 설치 명령:")
for p in problems:
    print(f"  {p}: {FIX.get(p, FIX['serif'])[OS]}")
if a.install:
    for p in problems:
        cmd = FIX.get(p, FIX["serif"])[OS]
        if cmd.startswith(("brew", "winget", PY)):
            if cmd.startswith("brew") and not shutil.which("brew"):
                print("Homebrew가 없습니다. 먼저 https://brew.sh 의 한 줄 명령으로 설치하세요."); continue
            print("실행:", cmd); subprocess.run(cmd, shell=True)
    print("다시 점검하려면 --install 없이 한 번 더 실행하세요.")
sys.exit(1)
