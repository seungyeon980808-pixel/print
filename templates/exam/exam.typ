// 시험지형 서식: 색 없이 검정 한 가지(평가원 문제지처럼). 평가원 문제지처럼 첫 쪽 머리 → 두 단 · 가운데 세로선 → 쪽당 4문항 칸 → 바깥쪽 아래 쪽 번호.
// 문항에 출처 · 표시(기출변형 등)는 찍지 않는다(학생용). 출처는 해설 · 검토 용지에만.
// 쓰는 값: brand.typ의 paper · size · accent · tone · font · radius · per-page · header · name-field · exam
#import "style.typ": brand, serif, sans, rad, per-page, header-style
#import "drill.typ": bogi, data-table, fit-cell, hair, rule, marks, plain, sentences

#let size = brand.size
#let gray = luma(90)   // 작은 안내 글씨만(색은 쓰지 않음)
#let ex = brand.exam
#let col-gap = 12mm
#let gap-m = 2.6mm

// ── 선지: 글자 수(문자열) 또는 cols 값으로 한 줄 5칸 · 3칸 · 2칸 · 1칸
#let choice-cols(cs, q) = {
  if "cols" in q { return q.cols }
  let n = cs.map(c => if type(c) == str { c.clusters().len() } else { plain(c).clusters().len() })
  if n.any(k => k > 14) { 1 } else if n.any(k => k > 8) { 2 } else if n.any(k => k > 7) { 3 } else { 5 }
}
#let choices(q) = {
  let cs = q.choices
  let k = choice-cols(cs, q)
  set par(justify: false)
  let item(i) = box[#marks.at(i)#h(1.4mm)#cs.at(i)]
  if k == 1 { grid(columns: (5.4mm, 1fr), row-gutter: 2mm, ..range(5).map(i => (marks.at(i), cs.at(i))).flatten()) }   // 긴 선지: 둘째 줄도 번호 뒤에 맞춤
  else { grid(columns: (1fr,) * k, row-gutter: 2.4mm, align: horizon, ..range(5).map(item)) }
}

// ── 자료: 표 · 직접 그린 그림 · 둘 나란히
// 그림은 그리지 않고 원본(기출 · 교과서 · 참고서)에서 잘라 온 파일만 쓴다: 작업/그림/<날짜>_<과목>_<판>_<번호>_<순번>.png
#let fig-dir = "/그림/"
#let material(m) = {
  if m.kind == "img" { align(center, image(fig-dir + m.file, width: m.at("width", default: 80%))) }
  else if m.kind == "draw" { align(center, m.body) }
  else if m.kind == "table" { data-table(m.rows, first: m.at("first", default: none)) }
  else if m.kind == "stack" { stack(spacing: gap-m, ..m.items.map(x => material(x))) }
  else if m.kind == "row" {
    grid(columns: m.at("widths", default: (1fr,) * m.items.len()), column-gutter: 4mm, align: center + bottom,
      ..m.items.map(x => material(x)))
  }
}

// 편집기: 문항 안 부분(지문 · 자료 · 발문 · 보기 · 선지)이 시작하는 자리. 보이지 않는다
#let mk-in(n, part) = context { let p = here().position(); [#metadata((n: n, part: part, page: p.page, x: p.x.pt(), y: p.y.pt())) <qpart>] }   // 글줄 안(지문 첫 글자 앞)
#let mk(n, part) = place(mk-in(n, part))   // 블록 사이: 흐름 밖에 두어 자리를 차지하지 않음
// ── 문항 하나: 「1.」 번호 뒤에 발문을 이어 쓰고, 둘째 줄부터는 번호만큼 들여 씀(평가원 방식)
#let pts(q) = if "points" in q { [ #text(font: sans, size: 0.84em)[\[#q.points;점\]]] }
#let problem(n, q) = block(breakable: false, width: 100%)[
  #metadata((n: n, answer: q.answer)) <answer>
  #context { let p = here().position(); [#metadata((n: n, page: p.page, x: p.x.pt(), y: p.y.pt(), w: page.width.pt(), h: page.height.pt())) <qpos>] }   // 편집기: 쪽에서 문항 위치
  #let nw = if n < 10 { 5.2mm } else { 7mm }   // 두 자리 번호는 칸을 넓혀 발문과 띄움
  #set par(justify: false, leading: 0.72em, hanging-indent: nw)
  #mk(n, "lead")
  #box(width: nw, text(font: sans, weight: "bold", size: 1.08em)[#n.])#q.lead
  #set par(hanging-indent: 0mm)
  #block(inset: (left: nw), width: 100%)[
    #if "material" in q [#v(gap-m)
      #mk(n, "material")
      #material(q.material)]
    #if "after" in q [#v(gap-m)
      #mk(n, "after")
      #q.after]
    #v(gap-m)
    #mk-in(n, "ask")#q.ask#pts(q)
    #if "bogi" in q [#v(gap-m + 1mm)
      #mk(n, "bogi")
      #bogi(q.bogi)]
    #v(gap-m + 0.6mm)
    #mk(n, "choices")
    #choices(q)
    #mk(n, "end")
  ]
]

// ── 첫 쪽 머리
#let line-box(w) = box(width: w, height: 3.2mm, stroke: (bottom: hair))
#let name-row() = {
  set text(font: sans, size: 8.4pt)
  if brand.name-field == "none" { [] }
  else if brand.name-field == "name" { [성명 #line-box(30mm)] }
  else { [#line-box(7mm) 학년#h(2mm)#line-box(7mm) 반#h(2mm)#line-box(7mm) 번#h(4mm)성명 #line-box(28mm)] }
}
#let exam-head(total) = {
  // 맨 위 띠: 학교 · 시험 이름 / 쪽 수
  grid(columns: (1fr, auto), align: bottom,
    text(font: sans, size: 8.4pt, tracking: 0.4pt)[#brand.org#h(2.5mm)#text(fill: gray)[|]#h(2.5mm)#ex.year #ex.name],
    text(font: sans, size: 8.4pt, fill: gray)[문제지 · 전체 #total;쪽])
  v(1.6mm)
  line(length: 100%, stroke: 1.6pt + black)
  v(4mm)
  // 가운데 큰 제목: 영역 + 과목
  grid(columns: (1fr, auto, 1fr), align: (left + horizon, center + horizon, right + horizon),
    box(stroke: 0.6pt + black, inset: (x: 2.6mm, y: 1.6mm), radius: rad(0mm),
      text(font: sans, weight: "bold", size: 9pt)[제 #ex.at("period", default: "4") 교시]),
    [#text(font: sans, weight: "bold", size: 22pt, tracking: 1pt)[#ex.area]
     #h(1.5mm)
     #text(font: sans, weight: "bold", size: 15pt)[(#ex.subject)]],
    name-row())
  v(4mm)
  line(length: 100%, stroke: rule)
  v(0.7mm)
  line(length: 100%, stroke: hair)
  v(5mm)
}

// ── 쪽 서식: 2쪽부터 머리에 과목 이름, 가운데 세로선, 바깥쪽 아래 쪽 번호(홀수 오른쪽 · 짝수 왼쪽)
#let pno(p) = box(width: 9mm, height: 7mm, stroke: 0.9pt + black, inset: 0mm)[
  #place(center + horizon, text(font: sans, weight: "bold", size: 12pt, str(p)))]
// 문항 글 규칙(시험지 · 해설 · 검토 용지가 함께 씀)
#let exam-text(body) = {
  set text(font: serif, size: size, lang: "ko")
  set par(spacing: 0.72em, justify: false)
  show "<보기>": "〈\u{2060}보\u{2060}기\u{2060}〉"
  show regex("[^\s]*[\u{AC00}-\u{D7A3}/][^\s]*"): box   // 한글이 든 어절(과 m/s 같은 단위)만 묶어 어절 단위로 줄바꿈 — 수식 글자는 건드리지 않아 기울임체가 산다
  show math.equation.where(block: false): it => it + sym.wj   // 수식 바로 뒤(「v로」)에서 줄이 갈리지 않게
  show math.equation: set text(font: "New Computer Modern Math")
  show math.frac: it => math.display(it)   // 분수는 평가원처럼 크게
  body
}
#let exam-page(total, body) = {
  show: exam-text
  set page(paper: brand.paper, margin: (x: 18mm, top: 22mm, bottom: 22mm),
    header: context {
      let p = counter(page).get().first()
      if p > 1 and header-style != "none" {
        set text(font: sans, size: 8.2pt)
        grid(columns: (1fr, auto, 1fr), align: (left + bottom, center + bottom, right + bottom),
          if calc.even(p) { text(weight: "bold")[#p] } else { text(fill: gray)[#ex.year #ex.name] },
          text(weight: "bold", tracking: 0.6pt)[#ex.area (#ex.subject)],
          if calc.odd(p) { text(weight: "bold")[#p] } else if header-style == "full" { text(fill: gray)[#brand.org] })
        v(-1.2mm); line(length: 100%, stroke: hair)
      }
    },
    background: context {
      let p = counter(page).get().first()
      let y0 = if p == 1 { 58mm } else { 24mm }
      place(top + center, dy: y0, line(angle: 90deg, length: page.height - y0 - 26mm, stroke: hair))
    },
    footer-descent: 6mm,
    footer: context {
      let p = counter(page).get().first()
      grid(columns: (1fr, auto, 1fr), align: (left + horizon, center + horizon, right + horizon),
        if calc.even(p) { pno(p) },
        text(font: sans, size: 7.4pt, fill: gray)[#p / #total],
        if calc.odd(p) { pno(p) })
    },
  )
  body
}

// ── 시험지 한 벌: questions를 쪽당 per-page개씩 칸에 넣음(왼쪽 단 위→아래, 오른쪽 단 위→아래)
#let exam(questions, start: 1, total: none, last-note: true) = {
  let pages = calc.ceil(questions.len() / per-page)
  let total = if total == none { pages } else { total }
  set document(title: ex.subject + " " + ex.name)
  exam-page(total, {
    exam-head(total)
    let rows = calc.ceil(per-page / 2)
    for (k, chunk) in questions.chunks(per-page).enumerate() {
      if k > 0 { pagebreak() }
      let prob(j) = problem(start + k * per-page + j, chunk.at(j))
      let cell(j) = if j < chunk.len() { fit-cell(prob(j)) } else { [] }
      // 줄 높이: 그 줄에서 가장 긴 문항 높이 + 같은 풀이 여백(긴 문항이 든 줄이 더 높아짐)
      layout(size => {
        let cw = (size.width - col-gap) / 2
        let hh(j) = if j < chunk.len() { measure(block(width: cw, prob(j))).height } else { 0pt }
        let hs = range(rows).map(r => calc.max(hh(r), hh(r + rows)))
        let slack = 45mm
        grid(columns: (1fr, 1fr), rows: hs.map(h => ((h + slack) / 1mm) * 1fr), column-gutter: col-gap, row-gutter: 8mm,
          ..range(rows).map(r => (cell(r), cell(r + rows))).flatten())
      })
    }
    if last-note {
      place(bottom + right, dy: -2mm, box(width: 46%, stroke: 0.6pt + black, inset: 3mm, radius: rad(0mm))[
        #set text(font: sans, size: 8pt)
        #set align(left)
        \* 확인 사항 \
        ◦ 답안지의 해당란에 필요한 내용을 정확히 기입(표기)했는지 확인하시오.])
    }
  })
}

// ── 해설 본문: explain이 배열이면(ㄱ · ㄴ · ㄷ) 문단마다 나누고 둘째 줄부터 들여 씀
#let explain-body(q, gap: 2.6mm) = if type(q.explain) == array {
  set par(hanging-indent: 5mm)
  q.explain.map(p => block(below: gap, p)).join()
} else { q.explain }
