// 검토 용지: 한 문항에 한 쪽. 색 없이 검정 한 가지.
// 위: 문항 정보 표 + 성취기준 원문
// 1줄: ① 참고 문항(칸 너비에 맞춤, 너무 길면 높이에서 멈춤) | ② 변형 문항(시험지와 같은 모양)
// 2줄: ③ 변형 근거 | ④ 문항 해설(ㄱ · ㄴ · ㄷ 문단)
// 3줄: ⑤ 체크리스트(작게) · AI에게 요청 | ⑥ 메모(남는 높이 전부, 세로로 길게)
// 다 쓴 뒤 스캔해서 작업/검토스캔/에 넣으면, 쪽마다 오른쪽 위 「문항 번호 · 판」으로 어느 문항인지 찾아 고친다.
#import "style.typ": brand, serif, sans
#import "drill.typ": hair, rule, marks
#import "exam.typ": exam-text, problem, explain-body
#import "문항.typ": questions, V
#import "성취기준.typ": standards, area-of
#let ex = brand.exam
#let gray = luma(90)
#let num(k) = if k < 10 { "0" + str(k) } else { str(k) }
#set document(title: ex.subject + " " + ex.name + " 검토 용지")
#set text(font: sans, size: 8.6pt, lang: "ko")
#set par(justify: false, leading: 0.62em)
#show math.equation: set text(font: "New Computer Modern Math")
#set page(paper: brand.paper, margin: (x: 14mm, top: 12mm, bottom: 12mm),
  footer: context grid(columns: (1fr, auto),
    text(size: 7.6pt, fill: gray)[#brand.org · #ex.year #ex.name · #ex.subject · 검토 용지 판 #V],
    text(size: 8pt, weight: "bold")[#counter(page).display() / #counter(page).final().first()]))

#let box-o = box(width: 3.2mm, height: 3.2mm, stroke: 0.5pt, baseline: 15%)
#let checks = ("정답이 하나뿐인가", "성취기준과 맞는가", "교육과정 밖 개념은 없는가", "자료(그림·표·그래프)가 정확한가",
  "발문과 조건이 분명한가", "선지가 고르게 매력적인가", "오탈자·표기")
// AI에게 맡길 수 있는 고치기(체크 + 빈칸에 숫자 · 말을 적으면 그대로 반영)
#let blank(w) = box(width: w, height: 3mm, stroke: (bottom: hair))
#let ai-requests = ([숫자 · 조건만 바꾸기], [더 어렵게], [더 쉽게], [발문 · 조건 분명하게],
  [〈보기〉 #blank(5mm) 다시 짓기], [오답 선지 더 매력적으로], [정답 번호 → #blank(5mm)], [교과서 용어 · 기호로],
  [그림을 다른 원본으로], [다른 기출 · 자료로 교체], [해설 더 자세히], [배점 → #blank(5mm)점])
// 절 제목: 「① 참고 문항」처럼 굵은 글씨 + 가는 선
#let sec(t, note: none) = block(below: 1.8mm, width: 100%)[
  #text(weight: "bold", size: 9.4pt, t)#if note != none { h(2mm) + text(size: 7.6pt, fill: gray, note) }
  #v(-1.2mm)#line(length: 100%, stroke: hair)]
#let cell(body) = block(width: 100%, inset: 3mm, body)
#let cell-fill(body) = block(width: 100%, height: 100%, inset: 3mm, body)
#let th(t) = text(size: 7.4pt, weight: "bold", t)

// 참고 문항 그림: 칸 너비에 맞추고(폭 맞춤), 그러면 너무 길어지는 그림은 높이에서 멈춤(쪽 맞춤)
#let ref-image(path, max-h: 98mm) = layout(size => {
  let w = measure(image(path, width: size.width)).height
  if w <= max-h { image(path, width: size.width) } else { align(center, image(path, height: max-h)) }
})

#let review(q) = {
  // ── 맨 위: 문서 이름 · 검토자 / 문항 번호(스캔 때 찾는 표지)
  grid(columns: (1fr, auto), align: bottom,
    [#text(weight: "bold", size: 15pt)[#ex.subject 문항 검토 용지]#h(3mm)#text(fill: gray)[#brand.org · #ex.year #ex.name · 판 #V]
     #v(1.4mm)
     #text(fill: gray)[검토자 #box(width: 30mm, stroke: (bottom: hair), height: 3mm)#h(5mm)검토일 #box(width: 26mm, stroke: (bottom: hair), height: 3mm)]],
    box(stroke: 1.2pt, inset: (x: 4mm, y: 2.4mm), text(weight: "bold", size: 20pt)[문항 #num(q.no)]))
  v(2mm)
  line(length: 100%, stroke: 1.4pt)
  v(1.6mm)
  // ── 문항 정보 표
  table(columns: (9mm, 1.5fr, 1.4fr, 1.2fr, 1fr, 1fr, 1fr, 1.1fr, 1fr, 0.8fr, 0.9fr), stroke: hair, inset: (x: 2mm, y: 1.8mm), align: center + horizon,
    th[번호], th[성취기준], th[영역], th[출처], th[변형 정도], th[난이도], th[답 형식], th[자료], th[계산], th[정답], th[배점],
    text(weight: "bold", size: 10pt, str(q.no)), q.std, area-of(q.std), q.src, q.change, q.level, q.form, q.data,
    if q.calc [계산] else [비계산], text(size: 10pt, marks.at(q.answer - 1)), [#q.points;점],
    table.cell(colspan: 11, align: left, inset: (x: 2.4mm, y: 2mm))[#th[성취기준 원문]#h(2mm)\[#q.std\] #standards.at(q.std, default: "")])
  v(1mm)
  block(width: 100%, height: 1fr, stroke: rule, grid(columns: (1fr, 1fr), rows: (auto, auto, 1fr),
    stroke: (x, y) => (left: if x > 0 { hair } else { none }, top: if y > 0 { hair } else { none }),
    // 1줄: ① 참고 문항 | ② 변형 문항
    cell[
      #sec([① 참고 문항], note: [#q.orig-label · 원본 정답 #q.orig-answer])
      #ref-image("/참고원본/회색/" + q.orig)],
    cell[
      #sec([② 변형 문항], note: [시험지 #calc.ceil(q.no / 4)쪽 #q.no;번])
      #exam-text(problem(q.no, q))],
    // 2줄: ③ 변형 근거 | ④ 문항 해설
    cell[
      #sec([③ 변형 근거], note: [#q.src · 변형 #q.change])
      #text(size: 8pt, fill: gray)[출처: #q.source]
      #v(0.8mm)
      #set list(marker: [–], body-indent: 1.6mm, spacing: 1.5mm)
      #for h in q.how [- #h
      ]],
    cell[
      #sec([④ 문항 해설], note: [정답 #marks.at(q.answer - 1)])
      #exam-text[#set text(size: 9.4pt); #set par(leading: 0.78em); #explain-body(q, gap: 2.4mm)]],
    // 3줄: ⑤ 체크리스트(작게) · AI에게 요청 | ⑥ 메모(세로로 길게)
    cell-fill[
      #sec([⑤ 체크리스트], note: [○ 적절 · △ 수정 · × 교체])
      #table(columns: (1fr, 5.2mm, 5.2mm, 5.2mm), stroke: hair, inset: (x: 1.6mm, y: 1.3mm),
        align: (left + horizon, center + horizon, center + horizon, center + horizon),
        [], th[○], th[△], th[×],
        ..checks.map(c => (text(size: 7.8pt, c), [], [], [])).flatten())
      #v(1.4mm)
      #set text(size: 7.8pt)
      #grid(columns: (auto, 1fr), column-gutter: 2mm, row-gutter: 1.8mm,
        [예상 난이도], [#box-o 쉬움#h(1.4mm)#box-o 보통#h(1.4mm)#box-o 어려움],
        [최종 판정], [#box-o 그대로#h(1.4mm)#box-o 수정 후#h(1.4mm)#box-o 교체])
      #v(2.6mm)
      #sec([AI에게 요청], note: [체크하면 스캔 뒤 그대로 반영])
      #grid(columns: (1fr, 1fr), column-gutter: 2mm, row-gutter: 1.6mm, ..ai-requests.map(t => [#box-o #t]))],
    cell-fill[
      #sec([⑥ 메모], note: [고칠 곳 · 의견 · AI에게 할 말])
      #layout(size => {
        let k = calc.floor((size.height - 9mm) / 8.5mm)   // 제목 높이만큼 빼고
        for i in range(k) { v(8.5mm - 0.4pt); line(length: 100%, stroke: 0.3pt + luma(170)) }
      })],
  ))
}

#for (i, q) in questions.enumerate() {
  if i > 0 { pagebreak() }
  review(q)
}
