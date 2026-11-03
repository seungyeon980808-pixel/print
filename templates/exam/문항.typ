// {SUBJECT} 시험지 — 문항 내용. 문항을 고칠 때는 이 파일만 고칩니다.
// 시험지에는 lead · material · ask · bogi · choices · points만 찍히고, 나머지(출처 · 성취기준 · 해설 등)는 해설 · 검토 용지 · 문항표에 들어갑니다.
// 그림은 그리지 않는다: 기출 · 교과서 · 참고서의 원본 그림을 잘라 작업/그림/에 두고 img("번호_순번", width: 70%)로 넣는다.
// material: img(…) · (kind: "table", rows: (…)) · (kind: "row", items: (…)) · (kind: "stack", items: (…))
// 선지 칸 수를 직접 정하려면 cols: 5 · 3 · 2 · 1
// 해설 explain: [한 문단] 또는 ([ㄱ. …], [ㄴ. …], [ㄷ. …]) — 배열이면 문단마다 나눠 찍는다
// 항목: no · std(성취기준 코드) · level(쉬움 · 보통 · 어려움) · change(하 · 중 · 상) · src(기출 그대로 · 기출 변형 · 교과서 변형 · 참고서 변형 · 기타 자료 변형)
//       orig(작업/참고원본/의 원본 그림 파일) · orig-label · orig-answer · how(변형 근거, 줄마다) · source(출처 한 줄)
//       form(합답형 · 정답형) · data(그림 · 표 · 그래프 · 그림+표 … · 자료 없음) · calc(true/false) · points · figs(그림 번호 목록)
#import "drill.typ": data-table
#import "style.typ": sans

#let V = "v1"
#let NAME = "{NAME}"            // 날짜_과목(띄어쓰기 없이). 그림 이름 = NAME_V_번호_순번.png
#let img(n, width: 70%) = (kind: "img", file: NAME + "_" + V + "_" + n + ".png", width: width)
#let bogi-choices = ("ㄱ", "ㄴ", "ㄱ, ㄷ", "ㄴ, ㄷ", "ㄱ, ㄴ, ㄷ")
#let bogi-choices2 = ("ㄱ", "ㄷ", "ㄱ, ㄴ", "ㄴ, ㄷ", "ㄱ, ㄴ, ㄷ")
#let bogi-choices3 = ("ㄱ", "ㄴ", "ㄱ, ㄴ", "ㄱ, ㄷ", "ㄴ, ㄷ")

#let questions = (
  // ───────── 1 ─────────
  (
    no: 1, std: "{CODE}", level: "보통", change: "하", src: "기출 변형",
    orig: "원본_01_<자료>_<쪽 · 번호>.png", orig-label: "<원본 이름 · 쪽 · 번호>", orig-answer: "<원본 정답>",
    how: ("그림: 그대로", "숫자: …", "묻는 것: …",),
    source: "<출처 한 줄>",
    form: "합답형", data: "그림", calc: false, points: 3, figs: ("01_1",),
    lead: [발문 앞부분(상황 · 자료 설명).],
    material: img("01_1", width: 70%),
    ask: [이에 대한 설명으로 옳은 것만을 \<보기\>에서 있는 대로 고른 것은?],
    bogi: ([보기 ㄱ], [보기 ㄴ], [보기 ㄷ]),
    choices: bogi-choices, answer: 3,
    explain: ([ㄱ. 까닭.], [ㄴ. 까닭.], [ㄷ. 까닭.]),
  ),
)
