// 서식 선택값: brand.typ의 값을 읽어 서식 파일(drill · concept · cover · 표지그림)이 쓰는 모양으로 바꾼다.
// brand.typ에 없는 값은 「별과 우주」 모양이 기본이다(옛 책의 brand.typ도 그대로 돈다).
#import "brand.typ": brand as base
#let opt(k, d) = base.at(k, default: d)

#let tone = opt("tone", "2도")                      // "2도"(검정 + 포인트 색) · "흑백"(복사용) · "컬러"
#let brand = base + (accent: if tone == "흑백" { luma(35) } else { base.accent })

#let font-style = opt("font", "serif")              // "serif" 명조 본문 + 고딕 제목 · "sans" 고딕만 · "allserif" 명조만
#let serif-fonts = ("KoPub Batang", "Noto Serif KR", "AppleMyungjo")
#let sans-fonts = ("Pretendard", "Noto Sans KR", "Apple SD Gothic Neo")
#let serif = if font-style == "sans" { sans-fonts } else { serif-fonts }   // 본문
#let sans = if font-style == "allserif" { serif-fonts } else { sans-fonts }  // 번호 · 제목 · 표 머리

// 상자 · 배지 모서리: brand.radius가 없으면 자리마다 원래 값(배지 0.5mm · 퀴즈 1mm · 〈보기〉 0)
#let rad(d) = { let r = opt("radius", none); if r == none { d } else { r } }

#let per-page = opt("per-page", 4)                  // 문항편 쪽당 문항 수: 2 · 4 · 6
#let answer-box = opt("answer-box", "space")        // 서답형 답 칸: "space" 여백만 · "line" 밑줄 「답 ___」 · "box" 답 상자
#let answers-at = opt("answers", "part")            // 정답 · 해설: "part" 파트 끝 · "end" 책 맨 뒤 · "teacher" 교사용 따로(교사용.typ)
#let header-style = opt("header", "full")           // 머리글: "full" 파트 이름 + 소속 · 이름 · "title" 파트 이름만 · "none" 없음
