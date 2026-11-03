// 시험지 세트 설정: 학교 · 시험 · 과목은 여기 한 곳에. 서식 파일(exam · 해설 · 검토용지 · drill)은 고치지 않는다.
#let brand = (
  org: "{SCHOOL}",              // 학교 이름(시험지 맨 위 · 짝수 쪽 머리)
  author: "과학과",
  role: "출제",
  slogan: "",
  sayings: (),
  copyright: ("기출 변형 문항의 원문항 저작권은 한국교육과정평가원에 있습니다.",),

  paper: "jis-b4",              // 시험지 용지: "jis-b4" · "a4"
  size: 9.6pt,                  // 본문 글자 크기
  accent: black,
  tone: "흑백",                 // 시험지 세트는 색을 쓰지 않는다(평가원식)
  font: "serif",
  radius: 0mm,
  per-page: 4,                  // 쪽당 문항 수(두 단)
  answer-box: "space",
  answers: "part",
  header: "full",
  name-field: "full",           // 학년 · 반 · 번 · 성명
  grade-label: "",
  head: "b",

  // ── 시험지(exam.typ가 읽음)
  exam: (
    year: "{YEAR}",             // 예: 2026학년도 2학기
    name: "{EXAM}",             // 예: 기말고사
    subject: "{SUBJECT}",       // 예: 역학과 에너지
    area: "{AREA}",             // 예: 과학탐구 영역
    period: "{PERIOD}",         // 교시
  ),
)
