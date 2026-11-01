"""새 책의 원본 폴더를 만든다: 서식 복사 + 파트 뼈대 + order.typ(문항 번호 잇기) + 책.typ(한 권 묶기).
사용: python3 new_book.py <자료폴더>/원본 --parts "별까지의 거리,별의 등급과 밝기" \
        [--series "별과 우주 기출 탐구"] [--school "대왕중학교"] [--course "2학년 과학 기말고사 대비"]
이미 있는 파일은 덮어쓰지 않는다(파트를 늘릴 때 다시 실행해도 안전). 다 만든 뒤 brand.typ를 브리프대로 채운다.
"""
import argparse, os, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TPL = os.path.join(HERE, "..", "templates")

ap = argparse.ArgumentParser()
ap.add_argument("dir")
ap.add_argument("--parts", required=True, help="파트 이름을 쉼표로(교과서 소단원 순서대로)")
ap.add_argument("--series", default="기출 탐구")
ap.add_argument("--school", default="")
ap.add_argument("--course", default="")
a = ap.parse_args()
names = [x.strip() for x in a.parts.split(",") if x.strip()]
if not names:
    sys.exit("파트 이름이 없습니다")
root = os.path.abspath(a.dir)
os.makedirs(root, exist_ok=True)

def put(path, text):
    if os.path.exists(path):
        print("있음(그대로 둠):", os.path.relpath(path, root)); return
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("만듦:", os.path.relpath(path, root))

for f in ("brand.typ", "style.typ", "drill.typ", "concept.typ", "cover.typ", "표지그림.typ"):
    dst = os.path.join(root, f)
    if os.path.exists(dst):
        print("있음(그대로 둠):", f)
    else:
        shutil.copy(os.path.join(TPL, f), dst); print("복사:", f)

fill = lambda t, n, title: (t.replace("{N}", str(n)).replace("{TITLE}", title)
                            .replace("{SERIES}", a.series).replace("{SCHOOL}", a.school).replace("{COURSE}", a.course))
for n, title in enumerate(names, 1):
    d = os.path.join(root, f"파트{n}")
    os.makedirs(os.path.join(d, "img"), exist_ok=True)
    for f in ("content.typ", "개념편.typ", "문항편.typ"):
        put(os.path.join(d, f), fill(open(os.path.join(TPL, "part", f), encoding="utf-8").read(), n, title))

k = len(names)
# order.typ와 책.typ는 파트 수에 따라 매번 새로 쓴다(직접 고칠 내용이 없음)
with open(os.path.join(root, "order.typ"), "w", encoding="utf-8") as f:
    f.write("// 파트 순서와 문항 시작 번호. 앞 파트의 문항 수를 자동으로 세어 번호가 1번부터 끝까지 이어진다. (new_book.py가 만듦)\n")
    f.write("".join(f'#import "파트{n}/content.typ" as p{n}\n' for n in range(1, k + 1)))
    f.write(f"#let counts = ({', '.join(f'p{n}' for n in range(1, k + 1))},).map(p => p.questions.len())\n")
    f.write("#let start-of(n) = 1 + counts.slice(0, n - 1).sum(default: 0)\n")
parts = "(" + ", ".join(f"(p{n}.info, p{n}.questions, start-of({n}))" for n in range(1, k + 1)) + ",)"
head = "".join(f'#import "파트{n}/content.typ" as p{n}\n' for n in range(1, k + 1))
with open(os.path.join(root, "책.typ"), "w", encoding="utf-8") as f:
    f.write("// 한 권: 앞표지 → 파트마다 개념편 → 문항편 → 정답·해설 → 뒤표지. 표지는 쪽 번호에서 빼고, 쪽 번호와 문항 번호는 끝까지 이어진다. (new_book.py가 만듦)\n")
    f.write("// 정답 위치는 brand.typ의 answers: \"part\"면 파트마다 끝, \"end\"면 책 맨 뒤에 모아, \"teacher\"면 교사용.typ로 따로.\n")
    f.write('#import "cover.typ": cover-front, cover-back\n#import "style.typ": answers-at\n#import "drill.typ": answers-book\n#import "order.typ": start-of\n' + head)
    f.write("#cover-front\n#counter(page).update(1)\n")
    f.write("".join(f'#include "파트{n}/개념편.typ"\n#include "파트{n}/문항편.typ"\n' for n in range(1, k + 1)))
    f.write(f"#if answers-at == \"end\" {{ answers-book({parts}) }}\n#cover-back\n")
with open(os.path.join(root, "교사용.typ"), "w", encoding="utf-8") as f:
    f.write("// 교사용 정답·해설(brand.typ의 answers가 \"teacher\"일 때 build.py가 따로 뽑는다). (new_book.py가 만듦)\n")
    f.write('#import "drill.typ": answers-book\n#import "order.typ": start-of\n' + head)
    f.write(f"#answers-book({parts}, title: [교사용 정답과 해설])\n")
print(f"order.typ · 책.typ · 교사용.typ: 파트 {k}개")
print("다음: brand.typ를 브리프대로 채우고 python3 build.py", root)
