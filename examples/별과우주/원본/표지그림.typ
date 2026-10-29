// 표지 큰 그림: 가로 420 × 세로 297mm 한 장. 왼쪽 절반 = 뒤표지, 오른쪽 절반 = 앞표지(펼치면 이어짐).
// 인쇄용이므로 검정 + 포인트 색(ink) 한 가지, 명도 차이만 쓴다.
#import "brand.typ": brand
#let ink = brand.accent
#let mute = luma(105)
#let cap(t, c: mute, s: 8.4pt, tr: 0.5pt, w: "regular") = text(font: "Pretendard", size: s, tracking: tr, fill: c, weight: w, t)
#let body(t, c: black, s: 10pt, w: "regular") = text(font: "Pretendard", size: s, fill: c, weight: w, t)

// ── 은하 그림(420 × 297mm 캔버스 좌표)
#let GX = 196mm          // 은하 중심(책등보다 조금 뒤표지 쪽)
#let GY = 192mm
#let R = 168mm           // 원반 반지름
#let tilt = 0.30         // 옆으로 기울여 본 납작함
#let rand(n, seed) = {
  let x = seed
  let out = ()
  for i in range(n) { x = calc.rem(x * 1103515245 + 12345, 2147483648); out.push(x / 2147483648) }
  out
}
#let gpt(r, a) = (GX + r * calc.cos(a), GY + r * tilt * calc.sin(a))
#let galaxy = {
  // 원반 테두리(겹 고리)
  for i in range(9) {
    let r = R * (0.18 + i * 0.105)
    place(top + left, dx: GX - r, dy: GY - r * tilt, ellipse(width: 2 * r, height: 2 * r * tilt, stroke: 0.3pt + ink.transparentize(25% + i * 8%)))
  }
  // 나선팔 두 개(겹선으로 굵기 표현)
  for k in (0, 1) {
    // 팔 하나 = 안쪽은 진하고 바깥은 옅어지는 짧은 선분들
    let n = 140
    let pts = range(0, n + 1).map(i => {
      let t = i / n
      gpt(R * (0.16 + 0.84 * t), (t * 1.25 * calc.pi) * 1rad + k * 180deg + 20deg)
    })
    for i in range(n) {
      let t = i / n
      place(top + left, line(start: pts.at(i), end: pts.at(i + 1), stroke: (1.4pt - t * 1pt) + ink.transparentize(10% + t * 60%)))
    }
  }
  // 별가루: 중심에 많고 바깥에 적게
  let rs = rand(2400, 17)
  for i in range(800) {
    let r = R * calc.pow(rs.at(i * 3), 1.6) * 1.02
    let a = rs.at(i * 3 + 1) * 360deg
    let s = 0.18mm + rs.at(i * 3 + 2) * 0.32mm
    let (x, y) = gpt(r, a)
    place(top + left, dx: x - s, dy: y - s, circle(radius: s, fill: ink.transparentize(30% + rs.at(i * 3 + 2) * 50%)))
  }
  // 중심 팽대부
  for (i, k) in ((0, 1.0), (1, 0.62), (2, 0.34)) {
    let r = 22mm * k
    place(top + left, dx: GX - r, dy: GY - r * 0.6, ellipse(width: 2 * r, height: 2 * r * 0.6, fill: ink.transparentize(82% - i * 30%)))
  }
}
// 태양계: 중심에서 8500/15000 ≈ 0.57 R, 앞표지 쪽
#let SA = 22deg
#let SP = gpt(R * 0.57, SA)
#let art = box(width: 420mm, height: 297mm, {
  galaxy
  let (sx, sy) = SP
  place(top + left, dx: sx - 1.6mm, dy: sy - 1.6mm, circle(radius: 1.6mm, fill: white, stroke: 0.9pt + ink))
  place(top + left, dx: sx - 4.2mm, dy: sy - 4.2mm, circle(radius: 4.2mm, stroke: 0.4pt + ink))
  // 확대 원(돋보기) 위치와 연결선
  let (mx, my, mr) = (sx + 52mm, sy - 64mm, 24mm)
  place(top + left, line(start: (sx + 3mm, sy - 3mm), end: (mx - mr * 0.72, my + mr * 0.72), stroke: 0.4pt + ink))
  place(top + left, dx: mx - mr, dy: my - mr, circle(radius: mr, fill: white, stroke: 0.6pt + ink))
  // 확대 원 안: 연주 시차
  let (ex, ey) = (mx, my + mr * 0.5)
  place(top + left, dx: ex - 12mm, dy: ey - 2.6mm, ellipse(width: 24mm, height: 5.2mm, stroke: 0.35pt + ink))
  place(top + left, dx: ex - 1.6mm, dy: ey - 1.6mm, circle(radius: 1.6mm, fill: ink))
  let st = (mx + 1.5mm, my - mr * 0.62)
  for e in ((ex - 12mm, ey), (ex + 12mm, ey)) {
    place(top + left, line(start: e, end: st, stroke: 0.45pt + ink))
    place(top + left, dx: e.at(0) - 1mm, dy: e.at(1) - 1mm, circle(radius: 1mm, fill: white, stroke: 0.6pt + ink))
  }
  place(top + left, dx: st.at(0) - 1.1mm, dy: st.at(1) - 1.1mm, circle(radius: 1.1mm, fill: ink))
  place(top + left, dx: mx - mr, dy: my + mr + 3mm, box(fill: white, inset: (x: 1mm, y: 0.6mm), stack(spacing: 1.4mm,
    cap([Fig. 2 · 확대], c: ink, w: "bold"), body([태양계와 연주 시차], s: 9pt))))
  // 태양계 이름표
  place(top + left, dx: sx - 3mm, dy: sy + 6mm, box(fill: white, inset: (x: 1mm, y: 0.6mm), stack(spacing: 1.2mm, cap([태양계], c: ink, w: "bold", s: 9pt), cap([중심에서 약 8500 pc], s: 7.8pt))))
  // 은하 중심 이름표(뒤표지 쪽에 걸침)
  place(top + left, dx: 18mm, dy: 132mm, stack(spacing: 1.4mm, cap([Fig. 1 · 우리은하], c: ink, w: "bold"), cap([지름 약 30000 pc · 비스듬히 본 원반과 나선팔], s: 7.8pt)))
})
