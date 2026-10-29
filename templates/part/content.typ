// 파트 {N} · {TITLE} — 문항편 내용. 문항을 고칠 때는 이 파일만 고칩니다.
// tag: "기출"(그대로) · "기출변형"(평가원 기출을 수준에 맞게 고침) · "변형"(교과서 문항) · "제작"(교과서 탐구로 새로 만듦)
// 선택형: bogi(〈보기〉, 없어도 됨) · choices(선지 5개) · answer(정답 번호)
// 서답형: parts(소문항) · answer(답 배열). explain = 해설(정답 쪽에 문장마다 줄을 나눠 들어감)
// 자료 material: (kind: "fig", file: "그림.png", width: 80%) · (kind: "figs", items: (("a.png", "(가)"), ("b.png", "(나)")), height: 30mm)
//               · (kind: "table", rows: (("머리", "…"), ("값", "…"))) · (kind: "draw", body: 직접 그린 그림)
// 어려운 문항은 star: true(도전 표시), 배점은 points: 3
#import "../drill.typ": sans, hair, brand

#let info = (
  school: "{SCHOOL}",
  course: "{COURSE}",
  series: "{SERIES}",
  no: {N},
  title: "{TITLE}",
)

#let summary = (
  "핵심 한 줄",
  "핵심 한 줄",
)

#let questions = (
  (
    tag: "변형", source: "교과서 000쪽",
    lead: [발문 앞부분(상황·자료 설명).],
    ask: [옳은 것만을 \<보기\>에서 있는 대로 고른 것은?],
    bogi: ([보기 ㄱ], [보기 ㄴ], [보기 ㄷ]),
    choices: ("ㄱ", "ㄴ", "ㄱ, ㄷ", "ㄴ, ㄷ", "ㄱ, ㄴ, ㄷ"), answer: 1,
    explain: [ㄱ. 까닭. ㄴ. 까닭. ㄷ. 까닭.],
  ),
  (
    tag: "제작", source: "교과서 000쪽 탐구",
    lead: [탐구 상황 설명.],
    ask: [물음에 답하시오.],
    parts: ([소문항 1], [소문항 2]),
    answer: ("답 1", "답 2"),
    explain: [해설 문장. 해설 문장.],
  ),
)
