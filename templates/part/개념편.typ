// 파트 {N} · {TITLE} — 개념편. 글을 고칠 때는 [ ] 안만 바꿉니다.
// 쓸 수 있는 것: concept-box[제목][내용] · fig(그림, [캡션]) · ctab(열 너비, 칸…) · th[표 머리] · key[강조]
//               quiz(ox: (), fill: (), calc: ()) · essay([발문], conds: ()) · answers((정답…), essay-answer: [], essay-points: ())
#import "../concept.typ": *

#let info = (
  school: "{SCHOOL}", course: "{COURSE}",
  series: "{SERIES}", no: {N}, title: "{TITLE}",
  goals: ("배울 것 1", "배울 것 2", "배울 것 3"),
)

#show: body => concept-doc(info, body)

#concept-box[개념 1][
  - #key[용어]: 설명.
]

#quiz(
  ox: ([O·X 문장],),
  fill: ([빈칸 문장 #b 입니다.],),
  calc: ([계산 문제],),
)

#essay(
  [서논술형 발문.],
  conds: ([조건 1],),
)

#answers(
  ("O", "답", "답"),
  essay-answer: [예시 답안.],
  essay-points: ("채점 요소 1",),
)
