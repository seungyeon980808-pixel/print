// 표지 큰 그림: 가로 420 × 세로 297mm 한 장. 왼쪽 절반 = 뒤표지, 오른쪽 절반 = 앞표지(펼치면 이어짐).
// 기본 그림은 겹친 타원과 점. 책마다 단원을 대표하는 도해로 바꾼다(예: examples/별과우주/표지그림.typ의 우리은하).
// 인쇄용이므로 검정 + 포인트 색(ink) 한 가지, 명도 차이만 쓴다.
#import "style.typ": brand
#let ink = brand.accent

#let art = box(width: 420mm, height: 297mm, {
  let (cx, cy) = (200mm, 200mm)
  for i in range(10) {
    let r = 30mm + i * 16mm
    place(top + left, dx: cx - r, dy: cy - r * 0.32, ellipse(width: 2 * r, height: 2 * r * 0.32, stroke: 0.35pt + ink.transparentize(15% + i * 7%)))
  }
  place(top + left, dx: cx - 4mm, dy: cy - 4mm, circle(radius: 4mm, fill: ink))
  place(top + left, dx: cx + 96mm, dy: cy - 18mm, circle(radius: 2mm, fill: white, stroke: 0.8pt + ink))
})
