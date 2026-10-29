// 표지 서식(뮤지엄 포스터형). 글은 brand.typ의 cover, 큰 그림은 표지그림.typ의 art에서 가져온다.
// 앞뒤 표지를 펼치면 그림 한 장(420 × 297mm)이 이어진다. 인쇄용: 검정 + 포인트 색 한 가지.
#import "brand.typ": brand
#import "표지그림.typ": art

#let ink = brand.accent
#let mute = luma(105)
#let L = 18mm
#let W = 210mm - 2 * L
#let P(x, y, body) = place(top + left, dx: x, dy: y, body)
#let cap(t, c: mute, s: 8.4pt, tr: 0.5pt, w: "regular") = text(font: "Pretendard", size: s, tracking: tr, fill: c, weight: w, t)
#let body(t, c: black, s: 10pt, w: "regular") = text(font: "Pretendard", size: s, fill: c, weight: w, t)
#let byline = [#brand.org \ #text(weight: "bold")[#brand.author] #brand.role]
#let half(side) = box(width: 210mm, height: 297mm, clip: true, place(top + left, dx: if side == "front" { -210mm } else { 0mm }, art))
#let C = brand.cover

// ── 앞표지
#let cover-front = page(paper: "a4", margin: 0mm)[
  #place(top + left, half("front"))
  #P(L, 16mm, block(width: W, grid(columns: (1fr, auto), cap(C.kicker.at(0), c: black, w: "medium"), cap(C.kicker.at(1)))))
  #P(L, 21mm, line(length: W, stroke: 0.4pt))
  #for (i, t) in C.title.enumerate() {
    P(L, 34mm + i * C.title-size * 1.15, text(font: "Pretendard", size: C.title-size, weight: "thin", tracking: -C.title-size / 20, top-edge: "cap-height", t))
  }
  #if C.dot != none { P(C.dot.at(0), C.dot.at(1), circle(radius: 3.4mm, fill: ink)) }
  #P(L, 250mm, line(length: W, stroke: 0.4pt))
  #P(L, 256mm, block(width: W, grid(columns: (1fr,) * C.columns.len(), column-gutter: 5mm,
    ..C.columns.enumerate().map(((i, (k, v))) => stack(spacing: 2mm,
      cap(k, c: if i == 0 { ink } else { mute }, w: if i == 0 { "bold" } else { "regular" }, s: 9pt),
      body(if v == none { byline } else { v }, s: 9.6pt))))))
]

// ── 뒤표지
#let row(k, v) = (cap(k, c: ink, w: "bold", s: 8.6pt), body(v, s: 9.4pt))
#let cover-back = page(paper: "a4", margin: 0mm)[
  #place(top + left, half("back"))
  #P(L, 16mm, block(width: W, grid(columns: (1fr, auto), cap(C.back-title, c: black, w: "medium"), cap([만든 기록]))))
  #P(L, 21mm, line(length: W, stroke: 0.4pt))
  #if brand.slogan != "" { P(L, 34mm, block(width: W, text(font: "Pretendard", size: 30pt, weight: "thin", tracking: -1pt, brand.slogan))) }
  #P(L, 70mm, block(width: W)[
    #set par(leading: 0.6em)
    #grid(columns: (24mm, 1fr), row-gutter: 4.4mm, ..C.record.map(((k, v)) => row(k, if v == none { [#brand.org #text(weight: "bold")[#brand.author] #brand.role] } else { v })).flatten())])
  #P(L, 250mm, line(length: W, stroke: 0.4pt))
  #P(L, 256mm, block(width: W, grid(columns: (1fr, auto), align: bottom,
    cap(brand.copyright.join(linebreak()), s: 8.4pt),
    text(font: "Pretendard", size: 16pt, weight: "thin", tracking: -0.5pt, C.spine))))
]
