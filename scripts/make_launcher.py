"""자료 폴더 맨 위에 「편집기 열기」 더블클릭 파일을 만든다(맥 .command · 윈도우 .bat).
사용: python3 make_launcher.py <자료폴더>
더블클릭하면 <자료폴더>/작업/원본을 print 편집기로 열고 브라우저를 띄운다. 창을 닫으면 편집기도 꺼진다.
"""
import os, stat, sys

d = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
mac = os.path.join(d, "편집기 열기.command")
with open(mac, "w", encoding="utf-8", newline="\n") as f:
    f.write("""#!/bin/bash
# 5E_print 편집기 열기 — 이 창은 편집하는 동안 켜 두세요(닫으면 편집기가 꺼집니다)
cd "$(dirname "$0")"
PY=$(command -v python3 || command -v python)
if [ -z "$PY" ]; then echo "Python 3이 없습니다. AI에게 「편집기 열어 줘」라고 하면 설치해 줍니다."; read -n 1; exit 1; fi
if ! command -v typst >/dev/null; then echo "Typst가 없습니다. AI에게 「편집기 열어 줘」라고 하면 설치해 줍니다."; read -n 1; exit 1; fi
"$PY" _print/scripts/editor/serve.py 작업/원본 2>&1 | while IFS= read -r line; do
  echo "$line"
  case "$line" in *http://localhost:*) open "$(echo "$line" | grep -o 'http://localhost:[0-9]*')";; esac
done
""")
os.chmod(mac, os.stat(mac).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
win = os.path.join(d, "편집기 열기.bat")
with open(win, "w", encoding="utf-8", newline="\r\n") as f:
    f.write("""@echo off
chcp 65001 >nul
rem 5E_print 편집기 열기 - 이 창은 편집하는 동안 켜 두세요(닫으면 편집기가 꺼집니다)
cd /d "%~dp0"
where typst >nul 2>nul || (echo Typst가 없습니다. AI에게 "편집기 열어 줘"라고 하면 설치해 줍니다. & pause & exit /b 1)
start "" "http://localhost:8950"
py _print\\scripts\\editor\\serve.py 작업\\원본 || python _print\\scripts\\editor\\serve.py 작업\\원본
pause
""")
print("만듦:", mac); print("만듦:", win)
