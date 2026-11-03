// 정답과 해설(교사용): 색 없이 평가원 정답표처럼. 정답표(번호 · 정답 · 배점) → 문항마다 정답 · 문항 정보 · 해설(두 단)
#import "style.typ": brand, serif, sans
#import "drill.typ": hair, rule, marks
#import "exam.typ": exam-text, explain-body
#import "문항.typ": questions, V
#let ex = brand.exam
#let gray = luma(90)
#let ans(q) = marks.at(q.answer - 1)
#set document(title: ex.subject + " " + ex.name + " 정답과 해설")
#show: exam-text
#set page(paper: brand.paper, margin: (x: 18mm, top: 20mm, bottom: 20mm),
  background: context if counter(page).get().first() > 0 {
    place(top + center, dy: if counter(page).get().first() == 1 { 92mm } else { 20mm },
      line(angle: 90deg, length: page.height - (if counter(page).get().first() == 1 { 92mm } else { 20mm }) - 22mm, stroke: hair)) },
  footer: context align(center, text(font: sans, size: 8pt)[#ex.subject #ex.name 정답과 해설 · #counter(page).display() · 판 #V]))

// ── 머리: 시험지 첫 쪽과 같은 모양
#grid(columns: (1fr, auto), align: bottom,
  text(font: sans, size: 8.4pt)[#brand.org#h(2mm)|#h(2mm)#ex.year #ex.name],
  text(font: sans, size: 8.4pt)[교사용 · 배부 금지])
#v(1.6mm)
#line(length: 100%, stroke: 1.6pt)
#v(4mm)
#align(center, text(font: sans, weight: "bold", size: 20pt)[#ex.area (#ex.subject) 정답과 해설])
#v(4mm)
#line(length: 100%, stroke: rule)
#v(0.7mm)
#line(length: 100%, stroke: hair)
#v(4mm)

// ── 정답표: 번호 · 정답 · 배점(12문항씩 한 줄)
#{
  let n = questions.len()
  let per = 12
  set text(font: sans)
  for c in range(calc.ceil(n / per)) {
    let qs = questions.slice(c * per, calc.min(n, (c + 1) * per))
    table(columns: (14mm,) + (1fr,) * per, stroke: hair, inset: (y: 2.2mm), align: center + horizon,
      table.cell(fill: luma(235))[#text(size: 8pt, weight: "bold")[번호]], ..qs.map(q => table.cell(fill: luma(235), text(weight: "bold", size: 9pt, str(q.no)))), ..((none,) * (per - qs.len())),
      text(size: 8pt, weight: "bold")[정답], ..qs.map(q => text(font: serif, size: 11pt, ans(q))), ..((none,) * (per - qs.len())),
      text(size: 8pt, weight: "bold")[배점], ..qs.map(q => text(size: 8pt, str(q.points))), ..((none,) * (per - qs.len())))
    v(2mm)
  }
  align(right, text(size: 8pt)[총 #n;문항 · #questions.map(q => q.points).sum()점])
}
#v(4mm)

// ── 문항별 해설(두 단, 번호 순서)
#columns(2, gutter: 12mm)[
  #for q in questions {
    block(breakable: false, below: 6mm, width: 100%)[
      #grid(columns: (auto, 1fr), column-gutter: 2mm, align: horizon,
        text(font: sans, weight: "bold", size: 11pt)[#q.no.],
        [#text(font: sans, weight: "bold", size: 10pt)[정답 #ans(q)]#h(2mm)#text(font: sans, size: 7.6pt, fill: gray)[\[#q.std\] · #q.level · #q.form · #q.points;점]])
      #v(0.6mm)
      #line(length: 100%, stroke: hair)
      #v(0.4mm)
      #text(font: sans, size: 7.6pt, fill: gray)[출처: #q.source]
      #v(1mm)
      #set text(size: 9.4pt)
      #explain-body(q, gap: 2mm)
    ]
  }
  #v(2mm)
  #line(length: 100%, stroke: hair)
  #text(font: sans, size: 7.2pt, fill: gray, brand.copyright.join(linebreak()))
]
