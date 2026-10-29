// 파트 1 · 별까지의 거리 — 문항편 내용. 문항을 고칠 때는 이 파일만 고칩니다.
// tag: "기출"(그대로) · "기출변형"(평가원 기출을 중2 수준으로 고침) · "변형"(교과서 문항) · "제작"(교과서 탐구로 새로 만듦)
// 교과서: 중학교 과학 2(정대홍) Ⅷ. 별과 우주. 쪽수는 인쇄된 쪽 번호.
// 서답형은 parts(소문항)와 answer(답 배열), 선택형은 choices와 answer(번호). explain = 해설(정답 쪽 아래)
#import "../drill.typ": sans, hair, brand

#let info = (
  school: "대왕중학교",
  course: "2학년 과학B 기말고사 대비",
  series: "별과 우주 기출 탐구",
  no: 1,
  title: "별까지의 거리",
)

#let summary = (
  "연주 시차 = 6개월 간격 시차의 절반",
  "거리(pc) = 1 ÷ 연주 시차(″)",
  "1 pc ≈ 3.26 광년",
)

#let ink = brand.accent
#let pt(x, y, r: 1mm, c: black, s: none) = place(top + left, dx: x - r, dy: y - r, circle(radius: r, fill: c, stroke: s))
#let ln(a, b, st: 0.5pt + black) = place(top + left, line(start: a, end: b, stroke: st))
#let lb(x, y, t, s: 6.4pt) = place(top + left, dx: x, dy: y, text(font: sans, size: s, t))

// 280쪽 그림 1 바탕: 두 지점 A, B에서 나무를 보면 배경이 달라진다
#let fig-tree = box(width: 66mm, height: 36mm, {
  for (x, c, n) in ((10mm, rgb("4A78C2"), "파란 지붕"), (44mm, rgb("C9483B"), "빨간 지붕")) {
    place(top + left, dx: x, dy: 3mm, polygon(fill: c, (0mm, 5mm), (6mm, 0mm), (12mm, 5mm)))
    place(top + left, dx: x + 1mm, dy: 8mm, rect(width: 10mm, height: 6mm, stroke: 0.5pt))
    lb(x - 1mm, 15mm, n, s: 5.8pt)
  }
  place(top + left, dx: 31mm, dy: 17mm, circle(radius: 3mm, fill: rgb("6BAF6B")))
  place(top + left, dx: 33.4mm, dy: 22.5mm, rect(width: 1.2mm, height: 3mm, fill: rgb("8A5A3B")))
  ln((14mm, 32mm), (52mm, 10mm), st: 0.4pt + ink)
  ln((54mm, 32mm), (16mm, 10mm), st: 0.4pt + ink)
  pt(14mm, 32mm, r: 1.2mm, c: ink)
  pt(54mm, 32mm, r: 1.2mm, c: ink)
  lb(10mm, 33mm, [A], s: 7pt)
  lb(56mm, 33mm, [B], s: 7pt)
  lb(37mm, 18mm, [나무], s: 6pt)
})

// 309쪽 01 바탕: 6개월 간격으로 별 S를 관측한 시차
#let fig-sixmonth = box(width: 60mm, height: 34mm, {
  place(top + left, dx: 12mm, dy: 24mm, ellipse(width: 36mm, height: 8mm, stroke: 0.5pt + luma(140)))
  ln((12mm, 28mm), (30mm, 4mm), st: 0.45pt + ink)
  ln((48mm, 28mm), (30mm, 4mm), st: 0.45pt + ink)
  pt(30mm, 28mm, r: 2.2mm, c: rgb("F2B33D"))
  pt(12mm, 28mm, r: 1.2mm, c: ink)
  pt(48mm, 28mm, r: 1.2mm, c: ink)
  pt(30mm, 4mm, r: 1.2mm)
  lb(32mm, 1mm, [별 S])
  lb(26.4mm, 8.4mm, [0.4″], s: 6.4pt)
  lb(25.5mm, 30.6mm, [태양])
  lb(2mm, 30mm, [지구])
  lb(44mm, 31mm, [6개월 후 지구], s: 5.8pt)
})

// 283쪽 분석 바탕: 같은 하늘을 6개월 간격으로 찍은 사진(격자 한 칸 = 0.1″)
#let photo(label, sx, w: 34mm) = box(width: w, height: 27mm, {
  place(top + left, rect(width: w, height: 22mm, fill: rgb("12223D")))
  for i in range(1, 9) { place(top + left, line(start: (i * 4mm - 1mm, 0mm), end: (i * 4mm - 1mm, 22mm), stroke: 0.25pt + white.transparentize(70%))) }
  for j in range(1, 6) { place(top + left, line(start: (0mm, j * 4mm - 1mm), end: (w, j * 4mm - 1mm), stroke: 0.25pt + white.transparentize(70%))) }
  for (x, y) in ((5mm, 4mm), (27mm, 6mm), (14mm, 18mm), (31mm, 17mm), (19mm, 3mm)) {
    place(top + left, dx: x - 0.5mm, dy: y - 0.5mm, circle(radius: 0.5mm, fill: white))
  }
  place(top + left, dx: sx - 1.1mm, dy: 11mm - 1.1mm, circle(radius: 1.1mm, fill: rgb("FFD36E")))
  place(top + left, dx: sx + 1.4mm, dy: 7.6mm, text(font: sans, size: 6pt, fill: rgb("FFD36E"), weight: "bold")[S])
  place(top + left, dy: 23mm, box(width: w, align(center, text(font: sans, size: 6.6pt, label))))
})

// 283쪽 스스로 하기 3 바탕: 별 S를 6개월 간격으로 관측(1월 → 7월 → 다음 해 1월)
#let fig-cycle = box(width: 72mm, height: 20mm, {
  for (i, (lab, sx)) in (("1월", 8mm), ("7월", 16mm), ("다음 해 1월", 8mm)).enumerate() {
    let x0 = i * 24.5mm
    place(top + left, dx: x0, rect(width: 22mm, height: 14mm, fill: rgb("12223D")))
    for (x, y) in ((3mm, 3mm), (18mm, 4mm), (12mm, 11mm)) { place(top + left, dx: x0 + x, dy: y, circle(radius: 0.45mm, fill: white)) }
    place(top + left, dx: x0 + sx - 1mm, dy: 7mm - 1mm, circle(radius: 1mm, fill: rgb("FFD36E")))
    place(top + left, dx: x0, dy: 15mm, box(width: 22mm, align(center, text(font: sans, size: 6.2pt, lab))))
  }
})

#let questions = (
  (
    tag: "변형", source: "교과서 290쪽 콕콕 문제로 확인 1",
    lead: [다음은 시차와 연주 시차에 대한 설명이다.],
    bogi: ([멀리 떨어진 물체일수록 시차가 크다.], [시차를 이용하여 물체까지의 거리를 비교할 수 있다.], [별의 연주 시차를 구하려면 지구에서 1년 간격으로 별을 관측해야 한다.]),
    ask: [옳은 것만을 \<보기\>에서 있는 대로 고른 것은?],
    choices: ("ㄱ", "ㄴ", "ㄷ", "ㄱ, ㄴ", "ㄴ, ㄷ"), answer: 2,
    explain: [ㄱ. 물체가 멀수록 시차는 작다. ㄴ. 시차가 클수록 가까우므로 거리를 비교할 수 있다. ㄷ. 연주 시차는 6개월 간격으로 관측한 시차의 절반이다.],
  ),
  (
    tag: "변형", source: "교과서 280쪽 그림 1",
    lead: [그림은 떨어져 있는 두 지점 A, B에서 같은 나무를 바라보는 모습을 나타낸 것이다. A에서는 나무 뒤로 빨간 지붕 집이, B에서는 파란 지붕 집이 보인다.],
    material: (kind: "draw", body: fig-tree),
    ask: [물음에 답하시오.],
    parts: ([두 관측 지점과 물체가 이루는 각을 무엇이라고 하는가?], [나무가 A, B에서 더 멀리 있다면 이 각은 어떻게 되는가?], [이 각을 이용하면 무엇을 비교할 수 있는가?]),
    answer: ("시차", "작아진다", "물체까지의 거리"),
    explain: [두 관측 지점과 물체가 이루는 각이 시차이다. 물체가 멀수록 시차는 작아지므로, 시차로 물체까지의 거리를 비교할 수 있다.],
  ),
  (
    tag: "제작", source: "교과서 281쪽 탐구 「시차와 거리 관계 알아보기」",
    lead: [시차 측정 모형판에서 구멍 A와 B로 각각 별 S와 T를 보고, 별이 보이는 눈금 위치에 붙임딱지를 붙였다. 표는 두 붙임딱지 사이의 거리를 나타낸 것이다.],
    material: (kind: "table", rows: (("별", "S", "T"), ("두 붙임딱지 사이의 거리(칸)", "6", "2")), first: 42mm),
    ask: [물음에 답하시오.],
    parts: ([시차가 더 큰 별은 S와 T 중 어느 것인가?], [관측 지점에서 더 멀리 있는 별은 어느 것인가?], [별까지의 거리와 시차는 어떤 관계가 있는가?]),
    answer: ("S", "T", "멀수록 시차가 작다"),
    explain: [두 붙임딱지 사이의 거리가 멀수록 시차가 크다. 시차가 작은 T가 더 멀리 있다. 별이 멀수록 시차는 작아진다.],
  ),
  (
    tag: "변형", source: "교과서 283쪽 표 1 「별의 연주 시차와 거리」",
    lead: [표는 별의 연주 시차를 나타낸 것이다.],
    material: (kind: "table", rows: (("별", "프록시마 센타우리", "시리우스", "베가", "아르크투루스"), ("연주 시차(″)", "0.77", "0.38", "0.13", "0.09")), first: 18mm),
    ask: [이에 대한 설명으로 옳은 것만을 \<보기\>에서 있는 대로 고른 것은?],
    bogi: ([지구에서 가장 가까운 별은 프록시마 센타우리이다.], [시리우스까지의 거리는 베가까지의 거리보다 멀다.], [아르크투루스는 10 pc보다 멀리 있다.]),
    choices: ("ㄱ", "ㄴ", "ㄱ, ㄷ", "ㄴ, ㄷ", "ㄱ, ㄴ, ㄷ"), answer: 3,
    explain: [연주 시차가 클수록 가깝다. ㄴ. 시리우스(0.38″)가 베가(0.13″)보다 가깝다. ㄷ. 아르크투루스는 1 ÷ 0.09 ≈ 11 pc로 10 pc보다 멀다.],
  ),
  (
    tag: "기출", source: "2011학년도 수능 지구과학Ⅰ 7번",
    lead: [그림 (가)는 별의 연주 시차의 원리를 나타낸 것이고, (나)는 철수가 연주 시차를 이해하기 위해 연필을 들고 양쪽 눈을 번갈아 뜨면서 연필의 겉보기 위치 변화를 확인하는 모습이다.],
    material: (kind: "figs", items: (("e1_2011_11_07_2.png", "(가)"), ("e1_2011_11_07_3.png", "(나)")), height: 34mm),
    ask: [(나)에 대한 설명으로 옳은 것만을 \<보기\>에서 있는 대로 고른 것은? ], points: 3,
    bogi: ([연필은 (가)에서 별 A에 해당한다.], [왼쪽 눈으로 본 후 이어서 오른쪽 눈으로 볼 때까지의 시간 간격은 (가)에서 6개월에 해당한다.], [눈과 연필 사이의 거리가 먼 경우는 (가)에서 연주 시차가 큰 경우에 해당한다.]),
    choices: ("ㄱ", "ㄷ", "ㄱ, ㄴ", "ㄴ, ㄷ", "ㄱ, ㄴ, ㄷ"), answer: 3,
    explain: [연필은 가까운 별 A, 두 눈은 6개월 간격의 지구 위치에 해당한다(ㄱ, ㄴ). 눈과 연필 사이가 멀면 시차가 작으므로 연주 시차가 작은 경우에 해당한다(ㄷ 틀림).],
  ),
  (
    tag: "기출변형", source: "2011학년도 9월 모의평가 지구과학Ⅰ 13번 (ㄷ 변형)",
    lead: [그림은 태양에서 가까운 별의 거리를 나타낸 것이다.],
    material: (kind: "fig", file: "e1_2011_09_13_1.png", width: 82%),
    ask: [이에 대한 설명으로 옳은 것만을 \<보기\>에서 있는 대로 고른 것은?],
    bogi: ([프록시마의 연주 시차는 1″보다 작다.], [버나드별의 연주 시차는 시리우스보다 크다.], [네 별 중 연주 시차가 가장 작은 별은 시리우스이다.]),
    choices: ("ㄱ", "ㄷ", "ㄱ, ㄴ", "ㄴ, ㄷ", "ㄱ, ㄴ, ㄷ"), answer: 3,
    explain: [ㄱ. 프록시마는 1.3 pc이므로 연주 시차는 1 ÷ 1.3 ≈ 0.77″로 1″보다 작다. ㄴ. 버나드별(1.8 pc)이 시리우스(2.7 pc)보다 가까우므로 연주 시차가 크다. ㄷ. 가장 먼 프로키온(3.5 pc)의 연주 시차가 가장 작다.],
  ),
  (
    tag: "변형", source: "교과서 309쪽 대단원 마무리 01",
    lead: [그림은 지구에서 6개월 간격으로 별 S를 관측했을 때 나타난 시차를 나타낸 것이다.],
    material: (kind: "draw", body: fig-sixmonth),
    ask: [이에 대한 설명으로 옳은 것만을 \<보기\>에서 있는 대로 고른 것은?],
    bogi: ([별 S의 연주 시차는 0.2″이다.], [별 S까지의 거리는 2.5 pc이다.], [지구로부터 멀리 있는 별일수록 연주 시차가 작아진다.]),
    choices: ("ㄱ", "ㄴ", "ㄱ, ㄷ", "ㄴ, ㄷ", "ㄱ, ㄴ, ㄷ"), answer: 3,
    explain: [ㄱ. 연주 시차는 시차 0.4″의 절반인 0.2″이다. ㄴ. 거리 = 1 ÷ 0.2 = 5 pc이다. ㄷ. 별이 멀수록 연주 시차는 작다.],
  ),
  (
    tag: "기출변형", source: "2015학년도 9월 모의평가 지구과학Ⅱ 12번 (자료 변형)",
    lead: [표는 별 A와 B를 6개월 간격으로 관측했을 때 나타난 위치 변화를 나타낸 것이다.],
    material: (kind: "table", rows: (("별", "A", "B"), ("6개월 간격 위치 변화(″)", "0.02", "0.12")), first: 38mm),
    ask: [별 A, B에 대한 설명으로 옳은 것만을 \<보기\>에서 있는 대로 고른 것은?],
    bogi: ([A는 100 pc의 거리에 있다.], [A의 거리는 B의 100배이다.], [B의 연주 시차는 0.12″이다.]),
    choices: ("ㄱ", "ㄴ", "ㄷ", "ㄱ, ㄴ", "ㄴ, ㄷ"), answer: 1,
    explain: [위치 변화의 절반이 연주 시차이다. A는 0.01″ → 100 pc, B는 0.06″ → 약 17 pc. A의 거리는 B의 약 6배이다.],
  ),
  (
    tag: "기출변형", source: "2014학년도 9월 모의평가 지구과학Ⅱ 18번 (자료 변형)",
    lead: [표는 별 (가)와 (나)를 6개월 간격으로 관측했을 때 나타난 위치 변화(시차)를 나타낸 것이다.],
    material: (kind: "table", rows: (("별", "(가)", "(나)"), ("6개월 간격 시차(″)", "0.2", "0.4")), first: 34mm),
    ask: [이에 대한 설명으로 옳은 것만을 \<보기\>에서 있는 대로 고른 것은?], points: 3,
    bogi: ([(가)까지의 거리는 10 pc이다.], [(나)의 연주 시차는 0.2″이다.], [지구로부터의 거리는 (가)와 (나)가 같다.]),
    choices: ("ㄱ", "ㄴ", "ㄷ", "ㄱ, ㄴ", "ㄱ, ㄷ"), answer: 4,
    explain: [(가)의 연주 시차는 0.1″ → 10 pc, (나)는 0.2″ → 5 pc. 연주 시차가 다르므로 거리도 다르다.],
  ),
  (
    tag: "변형", source: "교과서 283쪽 스스로 하기 3",
    lead: [그림은 별 S를 6개월 간격으로 관측한 모습이다. 1월과 7월에 관측한 S의 위치 차이는 0.6″이다.],
    material: (kind: "draw", body: fig-cycle),
    ask: [물음에 답하시오.],
    parts: ([별 S의 위치가 1년을 주기로 변하는 까닭은?], [별 S의 연주 시차는 몇 ″인가?], [별 S까지의 거리는 약 몇 pc인가? (소수점 둘째 자리에서 반올림)]),
    answer: ("지구가 1년 주기로 공전하기 때문", "0.3″", "약 3.3 pc"),
    explain: [지구가 태양 주위를 1년에 한 바퀴 공전하므로 별의 위치도 1년 주기로 변한다. 연주 시차는 0.6″의 절반인 0.3″, 거리는 1 ÷ 0.3 ≈ 3.3 pc이다.],
  ),
  (
    tag: "제작", source: "교과서 283쪽 「광년」 바탕",
    lead: [어떤 별 X의 연주 시차는 0.25″이다. (단, 1 pc는 약 3.26 광년이다.)],
    ask: [물음에 답하시오.],
    parts: ([별 X까지의 거리는 몇 pc인가?], [별 X까지의 거리는 약 몇 광년인가? (소수점 첫째 자리에서 반올림)], [별 X보다 2배 먼 곳에 있는 별의 연주 시차는 몇 ″인가?]),
    answer: ("4 pc", "약 13 광년", "0.125″"),
    explain: [1 ÷ 0.25 = 4 pc, 4 × 3.26 ≈ 13 광년. 거리가 2배가 되면 연주 시차는 1/2배이므로 0.125″이다.],
  ),
  (
    tag: "제작", star: true, source: "교과서 283쪽 분석 「연주 시차로 거리 비교하기」",
    lead: [그림은 같은 하늘을 6개월 간격으로 찍은 두 사진이다. 별 S는 가까운 별이고, 나머지 별들은 매우 먼 별이다. 격자 한 칸은 0.1″이다.],
    material: (kind: "draw", body: grid(columns: 2, column-gutter: 5mm, photo([1월], 7mm), photo([7월], 23mm))),
    ask: [물음에 답하시오.],
    parts: ([별 S의 연주 시차는 몇 ″인가?], [별 S까지의 거리는 몇 pc인가?], [다음 해 1월에 같은 하늘을 찍으면 별 S는 어디에 보이겠는가?]),
    answer: ("0.2″", "5 pc", "1월 사진과 같은 위치"),
    explain: [S는 4칸(0.4″) 움직였으므로 연주 시차는 그 절반인 0.2″, 거리는 1 ÷ 0.2 = 5 pc이다. 1년 뒤에는 지구가 같은 위치로 돌아오므로 S도 처음 위치에 보인다.],
  ),
)
