// 개념편 그림. 모두 Typst로 직접 그린다(외부 그림 없음). 그림 하나 = 너비 76mm 안쪽의 그림판.
#import "../drill.typ": brand, sans, gray, hair

#let ac = brand.accent
#let sun-c = rgb("F2B33D")

// ── 그리기 도구: 그림판 안 좌표(mm)로 놓는다
#let cv(w, h, body) = align(center, box(width: w, height: h, body))
#let dot(x, y, r: 1mm, fill: black, stroke: none) = place(top + left, dx: x - r, dy: y - r, circle(radius: r, fill: fill, stroke: stroke))
#let ln(a, b, st: 0.5pt + black) = place(top + left, line(start: a, end: b, stroke: st))
#let dash(c: gray) = (paint: c, thickness: 0.45pt, dash: "dashed")
#let lb(x, y, t, s: 6.6pt, c: black, a: "l", b: false) = {
  let body = text(font: sans, size: s, fill: c, weight: if b { "bold" } else { "regular" }, t)
  if a == "l" { place(top + left, dx: x, dy: y, body) }
  else if a == "c" { place(top + left, dx: x - 25mm, dy: y, box(width: 50mm, align(center, body))) }
  else { place(top + left, dx: x - 50mm, dy: y, box(width: 50mm, align(right, body))) }
}
#let arrow(a, b, st: 0.6pt + black, c: black) = {
  ln(a, b, st: st)
  let (ax, ay, bx, by) = (a.at(0) / 1mm, a.at(1) / 1mm, b.at(0) / 1mm, b.at(1) / 1mm)
  let t = calc.atan2(bx - ax, by - ay)
  let h = 1.7
  let p1 = (bx - h * calc.cos(t - 25deg), by - h * calc.sin(t - 25deg))
  let p2 = (bx - h * calc.cos(t + 25deg), by - h * calc.sin(t + 25deg))
  place(top + left, polygon(fill: c, stroke: none, (bx * 1mm, by * 1mm), (p1.at(0) * 1mm, p1.at(1) * 1mm), (p2.at(0) * 1mm, p2.at(1) * 1mm)))
}
#let pl(pts, st: 0.6pt + black) = place(top + left, curve(stroke: st, curve.move(pts.at(0)), ..pts.slice(1).map(p => curve.line(p))))
// 정해진 씨앗의 난수(매번 같은 그림)
#let rnd(n, seed) = {
  let x = seed
  let out = ()
  for i in range(n) { x = calc.rem(x * 1103515245 + 12345, 2147483648); out.push(x / 2147483648) }
  out
}
#let figcap(t) = align(center, text(font: sans, size: 7pt, fill: gray, t))

// ── 1. 연주 시차 원리
#let fig-parallax = cv(76mm, 50mm, {
  let r = rnd(40, 5)
  for i in range(13) { dot(r.at(i * 3) * 70mm + 3mm, r.at(i * 3 + 1) * 4mm + 2mm, r: 0.35mm, fill: gray) }
  lb(76mm, 0mm, [먼 별들(배경)], a: "r", c: gray, s: 6pt)
  place(top + left, dx: 16mm, dy: 38mm, ellipse(width: 44mm, height: 10mm, stroke: 0.5pt + gray))
  ln((38mm, 18mm), (38mm, 43mm), st: dash())
  ln((16mm, 43mm), (47.7mm, 7mm), st: 0.45pt + ac)
  ln((60mm, 43mm), (28.3mm, 7mm), st: 0.45pt + ac)
  dot(47.7mm, 7mm, r: 0.9mm, fill: white, stroke: 0.5pt + ac)
  dot(28.3mm, 7mm, r: 0.9mm, fill: white, stroke: 0.5pt + ac)
  lb(49.5mm, 7.2mm, [1월에 보이는 위치], s: 5.6pt, c: ac)
  lb(26.5mm, 7.2mm, [7월에 보이는 위치], s: 5.6pt, c: ac, a: "r")
  dot(38mm, 43mm, r: 2.4mm, fill: sun-c)
  lb(38mm, 46mm, [태양], a: "c")
  dot(16mm, 43mm, r: 1.3mm, fill: ac)
  dot(60mm, 43mm, r: 1.3mm, fill: ac)
  lb(14mm, 45.5mm, [지구(1월)], a: "r")
  lb(62mm, 45.5mm, [지구(7월)])
  dot(38mm, 18mm, r: 1.4mm)
  lb(40.5mm, 15.6mm, [가까운 별 S], b: true)
  lb(36.6mm, 21.5mm, [p], s: 8pt, c: ac, b: true, a: "r")
  lb(39.5mm, 30mm, [연주 시차 = 시차의 절반], s: 5.8pt, c: gray)
})

// ── 1. 거리와 연주 시차(반비례 그래프)
#let fig-inverse = cv(76mm, 48mm, {
  let (ox, oy) = (12mm, 38mm)
  let X(p) = ox + p * 58mm
  let Y(d) = oy - d * 3.3mm
  arrow((ox, oy), (ox + 62mm, oy))
  arrow((ox, oy), (ox, 2mm))
  lb(ox + 62mm, oy + 4.6mm, [연주 시차(″)], a: "r", s: 6pt)
  lb(ox + 1.5mm, 0.6mm, [거리(pc)], s: 6pt)
  pl(range(10, 101).map(i => (X(i / 100), Y(100 / i))), st: 1pt + ac)
  for (p, d) in ((1, 1), (0.5, 2), (0.2, 5), (0.1, 10)) {
    ln((X(p), Y(d)), (X(p), oy), st: dash())
    ln((ox, Y(d)), (X(p), Y(d)), st: dash())
    dot(X(p), Y(d), r: 0.9mm, fill: ac)
    lb(X(p), oy + 1.2mm, [#p], a: "c", s: 6pt)
    lb(ox - 1.4mm, Y(d) - 1.3mm, [#d], a: "r", s: 6pt)
  }
  lb(X(0.5) + 2mm, Y(2) - 5mm, [연주 시차가 반이면 \ 거리는 2배], s: 6pt, c: ac)
})

// ── 2. 거리와 밝기(빛이 퍼지는 넓이)
#let fig-light = cv(76mm, 40mm, {
  let cy = 15mm
  dot(5mm, cy, r: 1.8mm, fill: sun-c)
  lb(5mm, cy + 3mm, [별], a: "c", s: 6pt)
  ln((5mm, cy), (68mm, cy - 12.6mm), st: 0.4pt + gray)
  ln((5mm, cy), (68mm, cy + 12.6mm), st: 0.4pt + gray)
  for k in (1, 2, 3) {
    let x = 5mm + k * 21mm
    let h = k * 4.2mm
    place(top + left, dx: x - 0.8mm, dy: cy - h, rect(width: 1.6mm, height: 2 * h, fill: ac.lighten(60%), stroke: 0.4pt + ac))
    lb(x, 29.6mm, [거리 #k 배], a: "c", s: 6pt)
    lb(x, 32.8mm, [넓이 #(k * k) 배], a: "c", s: 6pt, c: gray)
    lb(x, 36mm, [밝기 #if k == 1 [1] else [1/#(k * k)] 배], a: "c", s: 6.2pt, c: ac, b: true)
  }
})

// ── 2. 등급 수직선
#let fig-mag = cv(76mm, 28mm, {
  let X(m) = 6mm + (m + 2) * 8mm
  let y = 14mm
  ln((X(-2), y), (X(6), y), st: 0.6pt)
  for m in range(-2, 7) {
    ln((X(m), y - 1mm), (X(m), y + 1mm), st: 0.5pt)
    lb(X(m), y + 1.6mm, [#if m > 0 [+#m] else [#m]], a: "c", s: 6pt)
  }
  lb(X(-2), 0mm, [← 밝다], s: 6.4pt, c: ac, b: true)
  lb(X(6), 0mm, [어둡다 →], s: 6.4pt, a: "r", b: true)
  for (m, n) in ((-1.5, "시리우스"), (0, "직녀성"), (2, "북극성"), (6, "맨눈 한계")) {
    dot(X(m), y, r: 1mm, fill: ac)
    lb(X(m), y - 6mm, n, a: "c", s: 5.8pt)
  }
  ln((X(1), 23mm), (X(6), 23mm), st: 0.5pt + ac)
  ln((X(1), 21.6mm), (X(1), 23mm), st: 0.5pt + ac)
  ln((X(6), 21.6mm), (X(6), 23mm), st: 0.5pt + ac)
  lb((X(1) + X(6)) / 2, 23.8mm, [5등급 차 = 밝기 100배], a: "c", s: 6pt, c: ac, b: true)
})

// ── 2. 겉보기 등급과 절대 등급(10 pc로 옮기기)
#let fig-abs = cv(76mm, 36mm, {
  let y = 14mm
  arrow((4mm, y), (74mm, y), st: 0.5pt)
  dot(4mm, y, r: 1.4mm, fill: ac)
  lb(4mm, y + 2mm, [지구], a: "c", s: 6pt)
  ln((36mm, 2mm), (36mm, 25mm), st: dash(c: ac))
  lb(36mm, 0mm, [10 pc], a: "c", s: 6.4pt, c: ac, b: true)
  dot(18mm, y, r: 1.2mm)
  lb(18mm, y + 2mm, [A], a: "c", s: 6.4pt, b: true)
  arrow((19.5mm, y - 4mm), (34.5mm, y - 4mm), st: 0.5pt + gray, c: gray)
  dot(62mm, y, r: 1.2mm)
  lb(62mm, y + 2mm, [B], a: "c", s: 6.4pt, b: true)
  arrow((60.5mm, y - 4mm), (37.5mm, y - 4mm), st: 0.5pt + gray, c: gray)
  place(top + left, dx: 0mm, dy: 26mm, box(width: 35mm, text(font: sans, size: 5.9pt)[#text(weight: "bold")[A] 10 pc보다 가까움 \ 옮기면 어두워짐 → #text(fill: ac, weight: "bold")[겉보기 \< 절대]]))
  place(top + left, dx: 40mm, dy: 26mm, box(width: 36mm, text(font: sans, size: 5.9pt)[#text(weight: "bold")[B] 10 pc보다 멂 \ 옮기면 밝아짐 → #text(fill: ac, weight: "bold")[겉보기 \> 절대]]))
})

// ── 2. 표면 온도와 색 띠
#let star-colors = (rgb("7FA6FF"), rgb("B7CCFF"), rgb("F4F6FF"), rgb("FFF4D6"), rgb("FFE08A"), rgb("FFB066"), rgb("FF7A5C"))
#let fig-color = cv(76mm, 25mm, {
  let w = 72mm
  lb(38mm, 0mm, [표면 온도 높다 ←#h(18mm)→ 표면 온도 낮다], a: "c", s: 6pt)
  place(top + left, dx: 2mm, dy: 4.5mm, rect(width: w, height: 5mm, stroke: hair, fill: gradient.linear(..star-colors)))
  let names = ("청색", "청백색", "백색", "황백색", "황색", "주황색", "적색")
  for (i, n) in names.enumerate() { lb(2mm + (i + 0.5) * w / 7, 10.6mm, n, a: "c", s: 6pt, b: true) }
  for (i, n) in ((1, "리겔"), (2, "시리우스"), (4, "태양"), (6, "베텔게우스")) {
    let x = 2mm + (i + 0.5) * w / 7
    dot(x, 18mm, r: 1.6mm, fill: star-colors.at(i), stroke: 0.4pt + gray)
    lb(x, 20.4mm, n, a: "c", s: 5.8pt)
  }
})

// ── 3. 우리은하 옆모습
#let fig-galaxy-side = cv(76mm, 34mm, {
  let (cx, cy) = (38mm, 14mm)
  let r = rnd(40, 9)
  for i in range(12) {
    let t = r.at(i * 2) * 360deg
    let k = 0.55 + r.at(i * 2 + 1) * 0.45
    dot(cx + 34mm * k * calc.cos(t), cy + 13mm * k * calc.sin(t), r: 0.7mm, fill: rgb("C0504D"))
  }
  place(top + left, dx: cx - 35mm, dy: cy - 2.2mm, ellipse(width: 70mm, height: 4.4mm, fill: ac.lighten(75%), stroke: 0.4pt + ac))
  place(top + left, dx: cx - 7mm, dy: cy - 4.5mm, ellipse(width: 14mm, height: 9mm, fill: ac.lighten(45%), stroke: 0.4pt + ac))
  let sx = cx + 35mm * 8500 / 15000
  dot(sx, cy, r: 1.1mm, fill: sun-c, stroke: 0.4pt + black)
  lb(sx, cy - 7.4mm, [태양계], a: "c", s: 6pt, b: true)
  ln((sx, cy - 4mm), (sx, cy - 1.3mm), st: 0.4pt)
  lb(cx, cy - 10.5mm, [중심부(팽대부)], a: "c", s: 5.8pt)
  lb(cx - 31mm, cy + 3mm, [원반], s: 5.8pt)
  lb(cx + 30mm, cy - 11.5mm, [● 구상 성단], s: 5.4pt, c: rgb("C0504D"), a: "r")
  ln((3mm, 30mm), (73mm, 30mm), st: 0.4pt)
  ln((3mm, 28.8mm), (3mm, 31.2mm), st: 0.4pt)
  ln((73mm, 28.8mm), (73mm, 31.2mm), st: 0.4pt)
  ln((cx, 26.6mm), (cx, 28.4mm), st: 0.4pt)
  place(top + left, dx: cx - 16mm, dy: 28.2mm, box(fill: white, inset: (x: 1mm), text(font: sans, size: 6pt)[지름 약 30000 pc]))
  place(top + left, dx: cx + 2mm, dy: 23.6mm, text(font: sans, size: 5.6pt, fill: gray)[중심 ↔ 태양계 약 8500 pc])
})

// ── 3. 우리은하 위에서 본 모습(막대 나선)
#let spiral(cx, cy, rmax, st: 1.6pt + ac.lighten(40%), bar: true, turn: 1.5) = {
  for k in (0, 1) {
    let pts = range(0, 61).map(i => {
      let th = i / 60 * turn * calc.pi
      let rr = rmax * (0.22 + 0.78 * i / 60)
      let a = th * 1rad + k * 180deg + 20deg
      (cx + rr * calc.cos(a), cy + rr * calc.sin(a))
    })
    pl(pts, st: st)
  }
  if bar { place(top + left, dx: cx - rmax * 0.26, dy: cy - 0.9mm, rotate(20deg, origin: center, rect(width: rmax * 0.52, height: 1.8mm, fill: ac.lighten(30%), stroke: none))) }
  else { dot(cx, cy, r: rmax * 0.16, fill: ac.lighten(30%)) }
}
#let fig-galaxy-top = cv(40mm, 40mm, {
  spiral(20mm, 20mm, 18mm)
  dot(20mm, 20mm, r: 2.4mm, fill: ac.lighten(20%))
  let a = 2.4 * 1rad + 20deg
  let rr = 18mm * (0.22 + 0.78 * 2.4 / (1.5 * calc.pi))
  dot(20mm + rr * calc.cos(a), 20mm + rr * calc.sin(a), r: 1.1mm, fill: sun-c, stroke: 0.4pt + black)
  lb(20mm + rr * calc.cos(a), 20mm + rr * calc.sin(a) + 1.6mm, [태양계], a: "c", s: 5.8pt, b: true)
})

// ── 3. 산개 성단과 구상 성단
#let fig-clusters = cv(76mm, 33mm, {
  for (i, t) in ((0, "산개 성단"), (1, "구상 성단")) {
    place(top + left, dx: 2mm + i * 38mm, dy: 0mm, rect(width: 34mm, height: 26mm, fill: rgb("12223D"), radius: 1mm))
    lb(19mm + i * 38mm, 27.6mm, t, a: "c", s: 6.4pt, b: true)
  }
  let r = rnd(80, 3)
  for i in range(22) { dot(5mm + r.at(i * 3) * 28mm, 3mm + r.at(i * 3 + 1) * 20mm, r: 0.35mm + r.at(i * 3 + 2) * 0.55mm, fill: rgb("BFD4FF")) }
  let q = rnd(900, 17)
  for i in range(300) {
    let rr = 11mm * calc.pow(q.at(i * 3), 1.8)
    let t = q.at(i * 3 + 1) * 360deg
    dot(57mm + rr * calc.cos(t), 13mm + rr * calc.sin(t), r: 0.22mm + q.at(i * 3 + 2) * 0.25mm, fill: rgb("FFC9A3"))
  }
})

// ── 3. 성운 세 가지
#let fig-nebulae = cv(76mm, 30mm, {
  let bg = rgb("12223D")
  let r = rnd(120, 21)
  for i in range(3) { place(top + left, dx: 1mm + i * 25.5mm, dy: 0mm, rect(width: 23.5mm, height: 22mm, fill: bg, radius: 1mm)) }
  // 방출: 붉게 스스로 빛남
  place(top + left, dx: 3mm, dy: 2.5mm, ellipse(width: 19.5mm, height: 17mm, fill: gradient.radial(rgb("FF6B6B"), rgb("C0392B").transparentize(40%), bg.transparentize(100%))))
  dot(12.5mm, 11mm, r: 0.9mm, fill: white)
  // 반사: 파랗게, 옆 별빛 반사
  place(top + left, dx: 29mm, dy: 4mm, ellipse(width: 18mm, height: 15mm, fill: gradient.radial(rgb("8FB4FF"), rgb("3D6FD9").transparentize(50%), bg.transparentize(100%))))
  dot(45mm, 6mm, r: 1.3mm, fill: white)
  // 암흑: 뒤쪽 별빛을 가림
  for i in range(30) { dot(52.5mm + r.at(i * 2) * 21.5mm, 1.5mm + r.at(i * 2 + 1) * 19mm, r: 0.32mm, fill: white) }
  place(top + left, dx: 56mm, dy: 4mm, ellipse(width: 15mm, height: 14mm, fill: rgb("05080F")))
  lb(12.75mm, 23.4mm, [방출 성운], a: "c", s: 6.4pt, b: true)
  lb(38.25mm, 23.4mm, [반사 성운], a: "c", s: 6.4pt, b: true)
  lb(63.75mm, 23.4mm, [암흑 성운], a: "c", s: 6.4pt, b: true)
})

// ── 4. 외부 은하 모양
#let fig-galaxy-types = cv(76mm, 24mm, {
  let names = ("타원 은하", "정상 나선 은하", "막대 나선 은하", "불규칙 은하")
  for i in range(4) { lb(9.5mm + i * 19mm, 18.6mm, names.at(i), a: "c", s: 5.8pt, b: true) }
  place(top + left, dx: 3mm, dy: 3mm, ellipse(width: 13mm, height: 10mm, fill: gradient.radial(ac.lighten(20%), ac.lighten(80%), white)))
  spiral(28.5mm, 8mm, 7.5mm, st: 1.1pt + ac.lighten(30%), bar: false, turn: 1.3)
  spiral(47.5mm, 8mm, 7.5mm, st: 1.1pt + ac.lighten(30%), turn: 1.2)
  let r = rnd(60, 31)
  for i in range(7) { dot(60mm + r.at(i * 2) * 13mm, 3mm + r.at(i * 2 + 1) * 10mm, r: 0.9mm + r.at(i + 20) * 1.4mm, fill: ac.lighten(40% + r.at(i + 30) * 40%)) }
})

// ── 4. 풍선 모형
#let fig-balloon = cv(76mm, 34mm, {
  let pts = (-60deg, 30deg, 160deg)
  let names = ("A", "B", "C")
  for (cx, rr, t) in ((17mm, 9mm, "부풀기 전"), (54mm, 15mm, "부푼 뒤")) {
    place(top + left, dx: cx - rr, dy: 15mm - rr, circle(radius: rr, fill: ac.lighten(88%), stroke: 0.6pt + ac))
    let xy = pts.map(a => (cx + rr * 0.72 * calc.cos(a), 15mm + rr * 0.72 * calc.sin(a)))
    ln(xy.at(0), xy.at(1), st: dash())
    ln(xy.at(1), xy.at(2), st: dash())
    ln(xy.at(0), xy.at(2), st: dash())
    for (i, p) in xy.enumerate() {
      dot(p.at(0), p.at(1), r: 1mm, fill: ac)
      lb(p.at(0) + 1.4mm, p.at(1) - 3mm, names.at(i), s: 6.2pt, b: true)
    }
    lb(cx, 31mm, t, a: "c", s: 6.2pt)
  }
  arrow((29mm, 15mm), (36mm, 15mm), st: 0.8pt + gray, c: gray)
})

// ── 4. 대폭발 우주론(시간 띠)
#let fig-bigbang = cv(76mm, 20mm, {
  place(top + left, dx: 4mm, dy: 2mm, polygon(fill: gradient.linear(ac, ac.lighten(80%)), stroke: none, (0mm, 5mm), (68mm, 0mm), (68mm, 10mm)))
  dot(4mm, 7mm, r: 1.6mm, fill: sun-c)
  lb(4mm, 13.4mm, [약 138억 년 전 \ 대폭발], s: 6pt, b: true)
  lb(72mm, 13.4mm, [현재 \ 계속 팽창 중], s: 6pt, a: "r", b: true)
  arrow((26mm, 16mm), (50mm, 16mm), st: 0.6pt + gray, c: gray)
  lb(38mm, 12.2mm, [식으면서 팽창], a: "c", s: 5.8pt, c: gray)
})

// ── 5. 우주 탐사 연표(세로): 왼쪽 세로선에 점, 연도 + 사건
#let timeline(items) = {
  set par(justify: false, leading: 0.55em)
  for (i, (y, t)) in items.enumerate() {
    grid(columns: (11mm, 1fr), column-gutter: 2mm,
      align(right, text(font: sans, weight: "bold", size: 8.6pt, fill: ac, y)),
      block(width: 100%, stroke: (left: 0.8pt + ac.lighten(55%)), inset: (left: 3.4mm, bottom: if i == items.len() - 1 { 0mm } else { 2.6mm }), below: 0mm)[
        #place(top + left, dx: -4.5mm, dy: 0.5mm, circle(radius: 1.1mm, fill: ac))
        #text(size: 8.6pt, t)])
  }
}

// ── 1. 연필로 시차 확인하기(탐구)
#let fig-pencil = cv(76mm, 44mm, {
  ln((4mm, 5mm), (72mm, 5mm), st: 0.8pt)
  for i in range(18) { ln((6mm + i * 3.8mm, 5mm), (6mm + i * 3.8mm, 7mm), st: 0.4pt) }
  lb(72mm, 0mm, [벽의 눈금 (= 먼 별들)], a: "r", s: 6pt, c: gray)
  ln((32mm, 38mm), (44.75mm, 6mm), st: 0.45pt + ac)
  ln((44mm, 38mm), (31.25mm, 6mm), st: 0.45pt + ac)
  dot(44.75mm, 6mm, r: 0.9mm, fill: ac)
  dot(31.25mm, 6mm, r: 0.9mm, fill: ac)
  lb(46.5mm, 8mm, [왼쪽 눈으로 볼 때], s: 5.6pt, c: ac)
  lb(29.5mm, 8mm, [오른쪽 눈으로 볼 때], s: 5.6pt, c: ac, a: "r")
  place(top + left, dx: 37.2mm, dy: 18mm, rect(width: 1.6mm, height: 8mm, fill: sun-c, stroke: 0.4pt))
  lb(40.5mm, 19.5mm, [연필 (= 가까운 별)], s: 6pt, b: true)
  dot(32mm, 38mm, r: 1.4mm, fill: white, stroke: 0.6pt)
  dot(44mm, 38mm, r: 1.4mm, fill: white, stroke: 0.6pt)
  lb(29.5mm, 37mm, [왼쪽 눈], a: "r", s: 6pt)
  lb(46.5mm, 37mm, [오른쪽 눈], s: 6pt)
  lb(38mm, 40.6mm, [두 눈 (= 6개월 간격의 지구)], a: "c", s: 5.8pt, c: gray)
})
