// 책 설정(print 스킬 서식): 브리프를 받으면 Claude가 이 파일부터 채운다.
// 이 책에서 바뀌는 값은 모두 여기 한 곳에. 서식 파일(drill · concept · cover)은 고치지 않는다.
#let brand = (
  // ── 사람·문구
  org: "소속",           // 소속
  author: "이름",                 // 이름
  role: "편저",                     // 표기: 편저 · 지음 · 엮음
  slogan: "슬로건 한 줄",   // \n = 줄바꿈
  // 쪽마다 아래에 돌아가며 들어가는 한마디(비우면 넣지 않음)
  sayings: (
    "쓸데없는 거 보지 말고 교과서 봐라.",
  ),
  // 저작권 문구(정답 쪽 · 뒤표지). 줄마다 하나
  copyright: ("© 문항 저작권은 한국교육과정평가원에 있습니다.",),

  // ── 모양: 브리프 끝 「서식 값」으로 이 블록의 값을 바꾼다(같은 키를 두 번 쓰면 오류)
  paper: "a4",                      // "a4" · "jis-b4" · "jis-b5"
  size: 9.6pt,                      // 본문 글자 크기: 9pt · 9.6pt · 10.5pt
  accent: rgb("1E4D8C"),            // 포인트 색(머리 탭·문항 표시·핵심 제목에만)
  tone: "2도",                      // "2도" · "흑백" · "컬러"
  font: "serif",                    // "serif" 명조 본문 + 고딕 제목 · "sans" 고딕만 · "allserif" 명조만
  radius: none,                     // 배지 · 상자 모서리: none(별과 우주: 배지 0.5mm · 퀴즈 1mm · 〈보기〉 0) · 0mm · 0.8mm · 2mm
  per-page: 4,                      // 문항편 쪽당 문항 수: 2 · 4 · 6
  answer-box: "space",              // 서답형 답 칸: "space" 여백만 · "line" 밑줄 · "box" 답 상자
  answers: "part",                  // 정답 · 해설: "part" 파트 끝 · "end" 책 맨 뒤 · "teacher" 교사용 따로
  header: "full",                   // 머리글: "full" · "title" 파트 이름만 · "none"
  name-field: "full",               // 학생 이름 칸: "full" 반·번호·이름 · "name" 이름만 · "none"
  grade-label: "2학년",             // 이름 칸 앞 학년
  head: "b",                        // 문항편 첫 쪽 머리: "a" 띠형 · "b" 세로 탭형 · "c" 숫자형

  // ── 표지(cover.typ가 읽음). 큰 그림은 표지그림.typ
  cover: (
    title: ("교재", "이름"),         // 앞표지 큰 제목(줄마다 하나)
    title-size: 118pt,
    kicker: ([Exhibition of Questions], [2026]),   // 앞표지 맨 위 왼쪽 · 오른쪽
    dot: (164mm, 56mm),              // 제목 옆 점 위치(none이면 없음)
    columns: (                       // 앞표지 아래 세 칸: (작은 제목, 내용)
      ([기출 탐구 학습지], [학교 학년 과목 \ 시험 대비]),
      ([파트], [파트 이름을 \ 짧게 나열]),
      ([엮은이], none),              // none = 소속 · 이름 · 표기를 자동으로
    ),
    back-title: [교재 이름 — 기출 탐구 학습지],
    record: (                        // 뒤표지 「만든 기록」
      ([출처], [한국교육과정평가원 수능 · 모의평가 기출 \ 교과서 이름, 단원, 쪽]),
      ([구성], [개념편 N부 · 문항 N]),
      ([도구], [Typst(조판) · print 스킬 \ 글꼴 KoPub 바탕 · Pretendard]),
      ([제작], [날짜]),
      ([엮은이], none),
    ),
    spine: [교재 이름],               // 뒤표지 오른쪽 아래 작은 제목
  ),
)
