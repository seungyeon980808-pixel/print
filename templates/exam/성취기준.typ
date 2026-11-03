// 2022 개정 교육과정 성취기준 원문(브리프 · find_standards.py에서 그대로). 과목이 바뀌면 이 표만 바꾼다.
// 해설 · 검토 용지가 문항의 std 코드로 원문을 찾아 찍는다.
#let standards = (
  "{CODE}": "{원문}",
)
// 영역 이름: 성취기준 코드 가운데 두 자리(01-, 02-, …)로 정한다. 과목의 영역 이름으로 바꾼다.
#let areas = ("01-": "{영역1}", "02-": "{영역2}", "03-": "{영역3}")
#let area-of(code) = { let k = areas.keys().find(k => code.contains(k)); if k == none { "" } else { areas.at(k) } }
