// 문제집형 공통 서식(드릴 계열). 내용은 각 학습지 폴더의 content.typ에서 고칩니다.
// 원칙: 검정 한 가지, 선과 여백으로만 구분, 본문 명조 · 번호/머리/표 머리 고딕, 모든 간격은 아래 값만 사용.

// 책마다 바뀌는 값은 brand.typ 한 곳에. 글꼴 · 색 · 모서리 · 쪽당 문항 수 · 답 칸 · 정답 위치 · 머리글은 style.typ가 brand.typ에서 읽음
#import "style.typ": brand, serif, sans, rad, per-page, answer-box, answers-at, header-style
#let size = brand.size     // 본문
#let gray = luma(110)
#let hair = 0.35pt + black // 가는 선
#let rule = 0.8pt + black  // 굵은 선

#let gap-q = 8mm           // 문항 사이 최소 여백(남는 높이는 풀이 공간으로 더 벌어짐)
#let gap-m = 2.4mm         // 발문 · 자료 · 보기 · 선지 사이
#let col-gap = 12mm

// 문항 표시: content.typ에서 tag: "기출" · "기출변형" · "제작", 어려우면 star: true(도전)

#let chip(t, filled: false) = box( fill: if filled { brand.accent } else { none },
  stroke: 0.5pt + brand.accent, inset: (x: 1.3mm, y: 0.8mm), radius: rad(0.5mm),
  text(font: sans, weight: "bold", size: 6.6pt, fill: if filled { white } else { brand.accent }, t))
#let tag-chip(t) = if t == "변형" { chip("교과서 변형") } else if t == "기출" { box(stroke: 0.5pt + luma(120), inset: (x: 1.3mm, y: 0.8mm), radius: rad(0.5mm), text(font: sans, weight: "bold", size: 6.6pt, fill: luma(80), t)) } else { chip(t) }

// 쪽 아래 한마디(쪽마다 돌아감). brand.sayings가 비면 넣지 않음
#let saying(p) = if brand.sayings.len() == 0 { [] } else { text(font: sans, size: 7.2pt, fill: brand.accent)[“#brand.sayings.at(calc.rem(p - 1, brand.sayings.len()))”] + h(4mm) }
#let num(n) = if n < 10 { "0" + str(n) } else { str(n) }

// ── 문항 머리: 번호 — 가는 선 — 출처
#let q-head(n, q) = grid(columns: (auto, auto, 1fr, auto), column-gutter: 2mm, align: horizon,
  text(font: sans, weight: "bold", size: 13.5pt, tracking: -0.4pt, top-edge: "cap-height", bottom-edge: "baseline", num(n)),
  [#tag-chip(q.at("tag", default: "기출"))#if q.at("star", default: false) [#h(1mm)#chip("도전", filled: true)]],
  line(length: 100%, stroke: hair),
  text(font: sans, size: 6.8pt, fill: gray, q.source),
)

// ── 자료
#let data-table(rows, first: none) = {
  let n = rows.at(0).len()
  align(center, table(
    columns: if first == none { (auto,) * n } else { (first,) + (1fr,) * (n - 1) },
    stroke: (x, y) => (top: if y == 0 { rule } else { hair }, bottom: if y == rows.len() - 1 { rule } else { none },
      left: if x > 0 { hair } else { none }),
    inset: (x: 2.4mm, y: 4pt), align: center + horizon,
    ..rows.enumerate().map(((y, row)) => row.map(c => if y == 0 { text(font: sans, size: 8.4pt, weight: "medium", c) } else { text(size: 9.4pt, c) })).flatten(),
  ))
}
#let figure-img(dir, file, width: 100%, height: auto) = align(center, image(dir + "/" + file, width: width, height: height))
#let cap(t) = text(font: sans, size: 7.4pt, t)

#let material(dir, m) = {
  if m.kind == "fig" { figure-img(dir, m.file, width: m.at("width", default: 90%)) }
  else if m.kind == "figs" {
    grid(columns: (1fr,) * m.items.len(), column-gutter: 3mm, row-gutter: 1.6mm, align: center + bottom,
      ..m.items.map(((f, c)) => image(dir + "/" + f, height: m.height)),
      ..m.items.map(((f, c)) => cap(c)))
  }
  else if m.kind == "draw" { align(center, m.body) }   // Typst로 직접 그린 자료
  else if m.kind == "table" { data-table(m.rows, first: m.at("first", default: none)) }
  else if m.kind == "side" {
    grid(columns: (1.15fr, 1fr), column-gutter: 3mm, align: horizon,
      data-table(m.rows), image(dir + "/" + m.file, height: m.height))
  }
}

// ── <보기>: 위 선 가운데에 글자를 얹는 평가원 방식
#let bogi(items) = block(width: 100%, inset: (top: 4mm, bottom: 3.4mm, x: 4mm), stroke: hair, radius: rad(0mm))[
  #place(top + center, dy: -4mm - 0.55em, box(fill: white, inset: (x: 1.8mm), text(font: sans, size: 7.8pt, tracking: 2pt)[〈보기〉]))
  #set par(leading: 0.72em, justify: false)
  #grid(columns: (5.6mm, 1fr), row-gutter: 2.6mm,
    ..items.enumerate().map(((i, t)) => ([#("ㄱㄴㄷㄹ".clusters().at(i)).], t)).flatten())
]

// ── 선지: 짧으면 한 줄 다섯 칸, 길면 세 칸 + 두 칸
#let marks = ("①", "②", "③", "④", "⑤")
#let choices(cs) = {
  let n = cs.map(c => c.clusters().len())
  set par(justify: false)
  let item(i) = box[#marks.at(i)#h(1.2mm)#cs.at(i)]
  // 문장 선지(14자 넘음)는 한 줄에 하나, 조금 길면 세 칸 + 두 칸, 짧으면 한 줄 다섯 칸
  if n.any(k => k > 14) { stack(spacing: 1.8mm, ..range(5).map(i => [#marks.at(i)#h(1.2mm)#cs.at(i)])) }
  else if n.any(k => k > 8) { grid(columns: (1fr, 1fr), row-gutter: 1.6mm, ..range(5).map(item)) }
  else if n.any(k => k > 4) { grid(columns: (1fr,) * 3, row-gutter: 1.6mm, ..range(5).map(item)) }
  else { block(width: 100%)[#range(5).map(item).join(h(1fr))] }
}

// ── 서답형: (1)(2)(3) 소문항, 줄 끝에 답 칸
// 답 칸은 따로 그리지 않음: 소문항만 붙여 쓰고, 문항 칸의 남는 여백이 풀이·답 공간
#let short-answers(parts) = {
  let rows = parts.enumerate().map(((i, t)) => ([(#(i + 1))], if answer-box == "line" {
    [#t #h(1fr) #text(font: sans, size: 8pt)[답] #box(width: 24mm, height: 0.9em, stroke: (bottom: hair))]
  } else if answer-box == "box" {
    [#t #v(1.2mm) #box(width: 100%, height: 9mm, stroke: hair, radius: rad(0mm))]
  } else { t }))
  // 기본(space): 소문항 아래마다 답을 적을 빈 여백(선·상자 없이)
  grid(columns: (6mm, 1fr), row-gutter: if answer-box == "space" { 10mm } else { 4mm }, ..rows.flatten())
}

// ── 문항 하나
#let problem(dir, n, q) = block(breakable: false, width: 100%, below: gap-q)[
  #metadata((n: n, answer: q.answer)) <answer>
  #q-head(n, q)
  #v(1.8mm)
  #set par(justify: false, leading: 0.66em)
  #q.lead
  #if "material" in q [#v(gap-m)#material(dir, q.material)]
  #v(gap-m)
  #q.ask#if "points" in q [ #text(font: sans, size: 8pt)[[#q.points;점]]]
  #if "bogi" in q [#v(gap-m)#bogi(q.bogi)]
  #v(gap-m)
  #if "parts" in q { short-answers(q.parts) } else { choices(q.choices) }
]

// ── 첫 쪽 제목(3가지 모양)
#let name-field() = if brand.name-field == "none" { [] } else if brand.name-field == "name" {
  text(font: sans, size: 8pt)[이름 #box(width: 24mm, stroke: (bottom: hair), height: 3mm)]
} else {
  text(font: sans, size: 8pt)[#brand.grade-label #box(width: 7mm, stroke: (bottom: hair), height: 3mm) 반 #box(width: 7mm, stroke: (bottom: hair), height: 3mm) 번#h(2.5mm)이름 #box(width: 24mm, stroke: (bottom: hair), height: 3mm)]
}
#let core-line(summary) = text(font: sans, size: 7.6pt)[#text(weight: "bold", fill: brand.accent)[핵심]#h(2.5mm)#summary.join(h(2mm) + text(fill: gray)[|] + h(2mm))]

#let title-block(info, summary, teacher, head) = {
  let side = if teacher { text(font: sans, size: 9pt, weight: "bold")[정답과 해설] } else { name-field() }
  let byline = text(font: sans, size: 7.2pt, fill: gray, tracking: 0.6pt)[#info.school #info.course#h(2mm)·#h(2mm)#brand.org #brand.author #brand.role]
  if head == "a" {
    // 띠형: 맨 위 포인트 색 띠, 큰 제목, 굵은 선, 핵심 줄
    block(width: 100%, height: 1.6mm, fill: brand.accent)
    v(3.2mm)
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      [#text(font: sans, size: 7.6pt, weight: "bold", fill: brand.accent, tracking: 1.2pt)[#info.series #num(info.no)]
       #v(-0.4mm)
       #text(font: sans, weight: "bold", size: 17pt, tracking: -0.6pt, info.title)],
      [#byline #v(1.4mm) #side])
    v(2.6mm); line(length: 100%, stroke: rule); v(1.8mm)
    core-line(summary); v(1.8mm); line(length: 100%, stroke: hair); v(5mm)
  } else if head == "b" {
    // 세로 탭형: 왼쪽 포인트 색 사각형 안에 번호, 오른쪽 제목
    grid(columns: (17mm, 1fr), column-gutter: 4mm,
      block(width: 17mm, height: 19mm, fill: brand.accent, inset: 2mm)[
        #set align(center + horizon)
        #text(font: sans, size: 6.5pt, fill: white, tracking: 1pt)[기출 탐구] \
        #text(font: sans, weight: "bold", size: 22pt, fill: white, num(info.no))],
      [#byline
       #v(0.6mm)
       #text(font: sans, weight: "bold", size: 16pt, tracking: -0.5pt, info.title)
       #v(1.2mm)
       #side])
    v(2.4mm); line(length: 100%, stroke: rule); v(1.8mm)
    core-line(summary); v(1.8mm); line(length: 100%, stroke: hair); v(5mm)
  } else {
    // 숫자형: 큰 번호를 포인트 색 가는 글씨로, 장식 없이
    grid(columns: (auto, 1fr, auto), column-gutter: 4mm, align: bottom,
      text(font: sans, weight: "light", size: 38pt, fill: brand.accent, tracking: -1.5pt, num(info.no)),
      [#byline #v(0.2mm) #text(font: sans, weight: "bold", size: 15pt, tracking: -0.4pt, info.title)],
      side)
    v(1.6mm); line(length: 100%, stroke: rule); v(1.8mm)
    core-line(summary); v(1.8mm); line(length: 100%, stroke: hair); v(5mm)
  }
}

// ── 개념 정리 쪽(섹션마다 한 쪽)
#let concept-head(t) = block(below: 2mm)[#text(font: sans, weight: "bold", size: 10.5pt, fill: brand.accent, t)#v(-1mm)#line(length: 100%, stroke: 0.6pt + brand.accent)]
#let concept-box(title, body) = block(breakable: false, width: 100%, below: 7mm)[
  #concept-head(title)
  #set par(justify: false, leading: 0.7em)
  #set list(marker: text(fill: brand.accent)[•], indent: 0mm, body-indent: 2mm, spacing: 1.6mm)
  #body
]
#let key(t) = text(font: sans, weight: "bold", t)

#let concept-page(info, concepts) = [
  #grid(columns: (auto, 1fr), column-gutter: 3mm, align: horizon,
    box(fill: brand.accent, inset: (x: 2mm, y: 1.2mm), text(font: sans, weight: "bold", size: 8pt, fill: white)[개념 정리]),
    text(font: sans, size: 8pt, fill: gray)[문제를 풀기 전에 꼭 알아야 할 것만 모았습니다.])
  #v(3.5mm)
  #columns(2, gutter: col-gap)[#concepts]
]

// ── 뒤쪽 빠른 정답
// 이 쪽에 절(파트 시작·정답 시작) 표시가 있는지: 머리글 숨김·세로선 판단에 씀
#let sec-on(p, kinds) = query(<sec>).any(m => m.value.at(0) in kinds and m.location().page() == p)
#let last-sec(p) = {
  let ms = query(<sec>).filter(m => m.location().page() <= p)
  if ms.len() == 0 { none } else { ms.last().value.at(0) }
}

#let ans-of(q) = if "parts" in q { q.answer.enumerate().map(((k, a)) => [(#(k + 1)) #a]).join(h(1.8mm)) } else { marks.at(q.answer - 1) }
#let sec-head(t, note: none) = grid(columns: (auto, 1fr), column-gutter: 3mm, align: horizon,
  box(fill: brand.accent, inset: (x: 2mm, y: 1.2mm), text(font: sans, weight: "bold", size: 8pt, fill: white, t)),
  if note == none { line(length: 100%, stroke: hair) } else { text(font: sans, size: 8pt, fill: gray, note) })
// 목록을 n단에 순서대로 고르게 나눔(왼쪽 단부터 위→아래)
#let split-cols(items, n, gutter: 5mm) = {
  let per = calc.ceil(items.len() / n)
  grid(columns: (1fr,) * n, column-gutter: gutter,
    ..range(n).map(c => items.slice(calc.min(c * per, items.len()), calc.min((c + 1) * per, items.len())).join()))
}

// 내용(content)을 글자만 뽑아 문자열로(해설을 문장 단위로 나누려고)
#let plain(c) = {
  if type(c) == str { c }
  else if c.has("text") { c.text }
  else if c.has("children") { c.children.map(plain).join() }
  else if c.has("body") { plain(c.body) }
  else if c.func() == [ ].func() { " " }
  else { "" }
}
// 문장 끝(". ")마다 나눔. ㄱ. ㄴ. ㄷ. 뒤는 나누지 않음
#let sentences(c) = {
  let t = plain(c)
  let out = ()
  let cur = ""
  for (k, part) in t.split(". ").enumerate() {
    cur += part
    let last = part.clusters().at(-1, default: "")
    if last in ("ㄱ", "ㄴ", "ㄷ") { cur += ". " } else { out.push(cur); cur = "" }
  }
  if cur != "" { out.push(cur) }
  out.map(x => if x.ends-with(".") { x } else { x + "." })
}

// ── 뒤쪽 빠른 정답 + 해설(번호 순서 그대로, 빈 공간 없이)
#let answer-page(info, questions, start: 1, label: false) = [
  #metadata(("ans", info.no)) <sec>
  #if label { block(below: 3.4mm, text(font: sans, weight: "bold", size: 11pt)[#text(fill: brand.accent)[#info.series #num(info.no)]#h(2mm)#info.title]) }
  #sec-head[빠른 정답]
  #v(2.4mm)
  #{
    set par(justify: false, leading: 0.5em, hanging-indent: 7mm)
    let items = questions.enumerate().map(((i, q)) => block(below: 1.7mm, breakable: false, grid(columns: (7mm, 1fr),
      text(font: sans, weight: "bold", size: 8.4pt, fill: brand.accent, num(start + i)), text(size: 8.8pt, ans-of(q)))))
    split-cols(items, 3)
  }
  #let ex = questions.enumerate().filter(((i, q)) => "explain" in q)
  #if ex.len() > 0 {
    v(3mm)
    sec-head[해설]
    v(2.6mm)
    // 해설: 번호 배지 + 정답 한 줄, 설명은 한 문장씩 줄을 나눔
    let entry(i, q) = block(breakable: false, below: 3mm, width: 100%, inset: (left: 2.4mm, y: 0.6mm), stroke: (left: 1pt + brand.accent.lighten(55%)))[
      #box(fill: brand.accent, inset: (x: 1.3mm, y: 0.7mm), radius: 0.5mm, text(font: sans, weight: "bold", size: 7.8pt, fill: white, num(start + i)))#h(1.6mm)#text(font: sans, weight: "bold", size: 8.4pt)[정답 #ans-of(q)]
      #v(0.6mm)
      #set text(size: 8.6pt)
      #set par(justify: false, leading: 0.58em)
      #sentences(q.explain).join(linebreak())   // 문장마다 줄바꿈
    ]
    // 두 단에 번호 순서대로 흐름(쪽을 넘어가도 왼쪽 단 → 오른쪽 단 → 다음 쪽 순서), 끝에 저작권 문구
    columns(2, gutter: col-gap)[
      #for (i, q) in ex { entry(i, q) }
      #v(2mm)
      #line(length: 100%, stroke: hair)
      #v(1.2mm)
      #text(font: sans, size: 7.2pt, fill: gray, brand.copyright.join(linebreak()))
    ]
  }
]

// 문항이 칸보다 크면 겹쳐 그리지 않고 칸에 맞게 줄인 뒤, 오른쪽 위에 빨간 「칸 넘침」을 단다(확인 그림에서 찾아 그림을 줄이거나 문항을 옮길 것)
#let fit-cell(body) = layout(size => {
  let h = measure(block(width: size.width, body)).height
  if h <= size.height + 6mm { body } else {   // 칸 사이 여백(6mm)까지는 넘쳐도 겹치지 않음
    let r = (size.height + 6mm) / h * 0.98
    place(top + right, dy: -4mm, text(font: sans, size: 7pt, weight: "bold", fill: rgb("C9302C"))[칸 넘침 · 그림을 줄이거나 문항을 옮기세요])
    scale(x: r * 100%, y: r * 100%, origin: top + left, reflow: true, block(width: size.width, body))
  }
})

// 문항편 · 정답 쪽 공통 쪽 서식(글꼴 · 어절 줄바꿈 · 머리글 · 세로선 · 쪽 아래 한마디)
#let page-doc(info, body) = {
  set text(font: serif, size: size, lang: "ko")
  set par(spacing: 0.66em, justify: false)
  show "<보기>": "〈\u{2060}보\u{2060}기\u{2060}〉"   // 줄 끝에서 쪼개지지 않게
  // 자간 맞춤: 양쪽 맞춤할 때 띄어쓰기만 벌리지 않고 글자 사이도 조금씩 줄이고 늘림(평가원 시험지처럼)
  set par(justification-limits: (spacing: (min: 75%, max: 130%), tracking: (min: -0.07em, max: 0.03em)))
  show regex("[^\s]+"): box   // 어절 단위 줄바꿈(한글 프로그램·평가원 시험지와 같은 방식)
  set page(paper: brand.paper, margin: (x: 20mm, top: 26mm, bottom: 16mm),
    // 위쪽: 왼쪽 학습지 이름, 오른쪽 쪽 번호(첫 쪽은 머리 대신 제목)
    header: context {
      let p = here().page()
      if header-style != "none" and not sec-on(p, ("start", "cstart")) {
        set text(font: sans, size: 7.4pt, fill: gray)
        grid(columns: (1fr, auto), align: bottom,
          [#text(fill: brand.accent, weight: "bold")[#info.series #num(info.no)]#h(2mm)#info.title],
          if header-style == "full" { text(font: sans, size: 7.4pt, fill: gray)[#brand.org #text(weight: "bold")[#brand.author]] })
        v(-1mm); line(length: 100%, stroke: hair)
      }
    },
    background: context {
      // 문항 쪽에만 가운데 세로선(정답 쪽부터는 없음). 파트 첫 쪽은 제목 아래부터
      let p = here().page()
      if last-sec(p) == "start" {
        let y0 = if sec-on(p, ("start",)) { 52mm } else { 28mm }
        place(top + center, dy: y0, line(angle: 90deg, length: page.height - y0 - 22mm, stroke: hair))
      }
    },
    // 아래: 오른쪽 구석에 쪽마다 바뀌는 한마디
    footer-descent: 5mm,
    footer: context {
      let p = here().page()
      // 파트 첫 쪽은 머리글이 없으므로 쪽 번호를 아래 왼쪽에
      // 오른쪽 아래: 잔소리 한 줄 + 쪽 번호
      align(right, [#saying(p)#text(font: sans, size: 10pt, weight: "bold", str(counter(page).get().first()))])   // 표지는 빼고 본문부터 1쪽
    },
  )
  body
}

// 정답 · 해설만 모아 찍기(brand.answers가 "end"면 책.typ 맨 뒤, "teacher"면 교사용.typ). parts = ((info, questions, start), …)
#let answers-book(parts, title: [정답과 해설]) = {
  for (k, (info, questions, start)) in parts.enumerate() {
    page-doc(info, [
      #if k == 0 { block(below: 5mm, text(font: sans, weight: "bold", size: 18pt, tracking: -0.5pt, title)) }
      #answer-page(info, questions, start: start, label: true)
    ])
  }
}

#let drill(info: (:), summary: (), questions: (), concepts: none, dir: "img", teacher: false, head: none, start: 1) = {
  let head = if head == none { brand.head } else { head }
  set document(title: info.series + " " + str(info.no))
  page-doc(info, {
  [#metadata(("start", info.no)) <sec>]
  v(-9mm)   // 첫 쪽은 머리글이 없으므로 그 자리만큼 제목을 올림
  title-block(info, summary, teacher, head)
  if concepts != none { concept-page(info, concepts); pagebreak() }
  let rows = calc.ceil(per-page / 2)
  for (k, chunk) in questions.chunks(per-page).enumerate() {
    if k > 0 { pagebreak() }
    // 쪽을 칸(왼쪽 단 위→아래, 오른쪽 단 위→아래)으로 나눠 문항 시작 높이를 맞춤. 칸의 남는 높이가 풀이 공간
    let cell(j) = if j < chunk.len() { fit-cell(problem(dir, start + k * per-page + j, chunk.at(j))) } else { [] }
    // 행 높이 1fr = 그 쪽에 남은 높이를 고르게(첫 쪽은 제목 아래만)
    grid(columns: (1fr, 1fr), rows: (1fr,) * rows, column-gutter: col-gap, row-gutter: 6mm,
      ..range(rows).map(r => (cell(r), cell(r + rows))).flatten())
  }
  if answers-at == "part" {
    pagebreak()
    answer-page(info, questions, start: start)
  }
  })
}
