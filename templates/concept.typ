// 개념편 공통 서식(파트마다 따로 배부). 쪽 규칙은 drill.typ와 같다: 위 오른쪽 쪽 번호, 아래 오른쪽 잔소리.
// 원칙: 내용은 두 단에 이어서 흘러 빈 공간을 만들지 않는다. 정답은 맨 뒤 한 곳.
#import "drill.typ": brand, sans, serif, size, gray, hair, rule, col-gap, key, num, sec-on, name-field, saying

// 개념 상자: 단·쪽을 넘어 나뉠 수 있게. 제목은 내용과 붙어 다님
#let concept-box(title, body) = block(width: 100%, breakable: true, below: 6mm)[
  #block(sticky: true, below: 2mm)[#text(font: sans, weight: "bold", size: 10.5pt, fill: brand.accent, title)#v(-1mm)#line(length: 100%, stroke: 0.6pt + brand.accent)]
  #set par(justify: false, leading: 0.7em)
  #set list(marker: text(fill: brand.accent)[•], indent: 0mm, body-indent: 2mm, spacing: 1.6mm)
  #body
]

// 표: 나뉘지 않음(split: true면 나뉨), 글씨 조금 작게, 양쪽 맞춤 끔. note는 표 아래 오른쪽 작은 글
#let ctab(cols, al: center + horizon, split: false, note: none, ..cells) = block(breakable: split, width: 100%)[
  #set text(size: 9pt)
  #set par(justify: false, leading: 0.55em)
  #table(columns: cols, stroke: (x, y) => (top: if y == 0 { rule } else { hair }, bottom: hair), inset: (x: 1.8mm, y: 2mm), align: al, ..cells)
  #if note != none { v(-1mm); align(right, text(font: sans, size: 7.4pt, fill: gray, note)) }
]
#let th(t) = text(font: sans, size: 8.6pt, weight: "bold", t)
#let formula(t) = align(center, box(stroke: hair, inset: (x: 3mm, y: 2.2mm), text(font: sans, weight: "bold", t)))
#let fig(f, cap) = block(breakable: false, width: 100%)[#f #align(center, text(font: sans, size: 7pt, fill: gray, cap))]
#let sup(t) = [\u{2060}#text(size: 6.4pt, baseline: -3.2pt, t)]
#let b = box(width: 15mm, stroke: (bottom: hair), height: 0.9em)

// 문항 묶음 머리(퀴즈 안 소제목)
#let qhead(t) = block(sticky: true, above: 3.4mm, below: 2mm, text(font: sans, size: 7.6pt, weight: "bold", fill: gray, t))
#let qnum(n) = box(width: 4.4mm, text(font: sans, weight: "bold", size: 8pt, fill: brand.accent)[#n])

// 확인 퀴즈: O·X, 빈칸, 계산(번호는 이어서). 단을 넘어 나뉠 수 있음
#let quiz(ox: (), fill: (), calc: ()) = block(width: 100%, breakable: true, stroke: 0.6pt + brand.accent, inset: 3.4mm, radius: 1mm, below: 6mm)[
  #block(sticky: true, text(font: sans, weight: "bold", size: 10pt, fill: brand.accent)[확인 퀴즈])
  #set par(justify: false, leading: 0.6em)
  #let n = 0
  #let row(n, t, tail) = block(below: 2.2mm, grid(columns: (4.6mm, 1fr, auto), column-gutter: 1mm, align: (left + top, left + top, right + bottom), qnum(n), t, tail))
  #if ox.len() > 0 {
    qhead[옳으면 O, 틀리면 X]
    for t in ox { n += 1; row(n, t, box(width: 6mm, height: 4.2mm, stroke: hair)) }
  }
  #if fill.len() > 0 {
    qhead[빈칸 채우기]
    for t in fill { n += 1; row(n, t, []) }
  }
  #if calc.len() > 0 {
    qhead[계산하기]
    for t in calc { n += 1; row(n, t, text(font: sans, size: 7.6pt)[답 #box(width: 16mm, height: 4.2mm, stroke: (bottom: hair))]) }
  }
]

// 서논술형: 발문 + 조건 + 모눈 답 칸
#let essay(prompt, conds: (), lines: 4) = block(width: 100%, breakable: false, below: 6mm)[
  #grid(columns: (auto, 1fr), column-gutter: 2.4mm, align: horizon,
    box(fill: brand.accent, inset: (x: 2mm, y: 1.2mm), text(font: sans, weight: "bold", size: 8pt, fill: white)[서논술형]),
    line(length: 100%, stroke: 0.6pt + brand.accent))
  #v(2mm)
  #set par(justify: false, leading: 0.68em)
  #prompt
  #if conds.len() > 0 {
    v(1.4mm)
    block(inset: (x: 3mm, y: 2mm), fill: brand.accent.lighten(92%), width: 100%)[
      #set text(size: 8.6pt)
      #text(font: sans, weight: "bold", size: 7.6pt)[조건] \
      #conds.map(c => [• #c]).join(linebreak())]
  }
  #v(2mm)
  // 답 칸: 예시 답안 길이에 맞춘 줄 몇 개(모눈 아님)
  #for i in range(lines) { block(width: 100%, height: 8mm, below: 0mm, stroke: (bottom: 0.4pt + luma(170))) }
]

// 정답(맨 뒤): (번호, 답) 배열 + 서논술 예시 답안
#let answers(list, essay-answer: none, essay-points: (), extra: none) = block(width: 100%, breakable: true, above: 2mm)[
  #grid(columns: (auto, 1fr), column-gutter: 3mm, align: horizon,
    box(fill: brand.accent, inset: (x: 2mm, y: 1.2mm), text(font: sans, weight: "bold", size: 8pt, fill: white)[정답]),
    line(length: 100%, stroke: hair))
  #v(2.4mm)
  #set par(justify: false, leading: 0.6em)
  #list.enumerate().map(((i, a)) => box[#text(font: sans, weight: "bold", size: 8pt, fill: brand.accent)[#(i + 1)]#h(1.2mm)#a]).join(h(3.4mm))
  #if essay-answer != none {
    v(3mm)
    text(font: sans, weight: "bold", size: 8pt)[서논술형 예시 답안]
    v(1mm)
    essay-answer
    if essay-points.len() > 0 {
      v(1.4mm)
      text(font: sans, size: 7.6pt, fill: gray)[채점 요소: #essay-points.enumerate().map(((i, p)) => [#(i + 1)) #p]).join(h(3mm))]
    }
  }
  #if extra != none { v(2mm); text(size: 8.6pt, extra) }
  #v(3mm)
  #line(length: 100%, stroke: hair)
  #v(1.4mm)
  #text(font: sans, size: 7pt, fill: gray, brand.copyright.join(linebreak()))
]

// 문서 틀: 첫 쪽 머리(세로 탭형) + 두 단 본문
#let concept-doc(info, body) = {
  set document(title: info.series + " " + str(info.no) + " 개념편")
  set text(font: serif, size: size, lang: "ko")
  set par(spacing: 0.66em, justify: false, leading: 0.68em)
  show "<보기>": "〈\u{2060}보\u{2060}기\u{2060}〉"
  // 자간 맞춤: 양쪽 맞춤할 때 띄어쓰기만 벌리지 않고 글자 사이도 조금씩 줄이고 늘림(평가원 시험지처럼)
  set par(justification-limits: (spacing: (min: 75%, max: 130%), tracking: (min: -0.07em, max: 0.03em)))
  show regex("[^\s]+"): box   // 어절 단위 줄바꿈
  set page(paper: brand.paper, margin: (x: 20mm, top: 26mm, bottom: 16mm),
    header: context {
      let p = here().page()
      if not sec-on(p, ("start", "cstart")) {
        set text(font: sans, size: 7.4pt, fill: gray)
        grid(columns: (1fr, auto), align: bottom,
          [#text(fill: brand.accent, weight: "bold")[#info.series #num(info.no) 개념편]#h(2mm)#info.title],
          text(font: sans, size: 7.4pt, fill: gray)[#brand.org #text(weight: "bold")[#brand.author]])
        v(-1mm); line(length: 100%, stroke: hair)
      }
    },
    background: context {
      let p = here().page()
      let y0 = if sec-on(p, ("cstart",)) { 52mm } else { 28mm }
      place(top + center, dy: y0, line(angle: 90deg, length: page.height - y0 - 22mm, stroke: hair))
    },
    footer-descent: 5mm,
    footer: context {
      let p = here().page()
      // 파트 첫 쪽은 머리글이 없으므로 쪽 번호를 아래 왼쪽에
      // 오른쪽 아래: 잔소리 한 줄 + 쪽 번호
      align(right, [#saying(p)#text(font: sans, size: 10pt, weight: "bold", str(counter(page).get().first()))])   // 표지는 빼고 본문부터 1쪽
    },
  )
  set list(marker: text(fill: brand.accent)[•], indent: 0mm, body-indent: 2mm, spacing: 1.6mm)
  [#metadata(("cstart", info.no)) <sec>]
  v(-9mm)
  grid(columns: (17mm, 1fr), column-gutter: 4mm,
    block(width: 17mm, height: 19mm, fill: brand.accent, inset: 2mm)[
      #set align(center + horizon)
      #text(font: sans, size: 6.5pt, fill: white, tracking: 1pt)[개념편] \
      #text(font: sans, weight: "bold", size: 22pt, fill: white, num(info.no))],
    [#text(font: sans, size: 7.2pt, fill: gray, tracking: 0.6pt)[#info.school #info.course#h(2mm)·#h(2mm)#brand.org #brand.author #brand.role]
     #v(0.6mm)
     #text(font: sans, weight: "bold", size: 16pt, tracking: -0.5pt, info.title)
     #v(1.2mm)
     #name-field()])
  v(2.4mm)
  line(length: 100%, stroke: rule)
  v(1.8mm)
  text(font: sans, size: 7.6pt)[#text(weight: "bold", fill: brand.accent)[이 파트에서]#h(2.5mm)#info.goals.join(h(2mm) + text(fill: gray)[|] + h(2mm))]
  v(1.8mm)
  line(length: 100%, stroke: hair)
  v(4mm)
  columns(2, gutter: col-gap, body)
}
