// 별과 우주 전체 교재 한 권: 앞표지 → 파트마다 개념편 → 문항편(정답·해설) 순서 → 뒤표지. 표지는 쪽 번호에서 빼고, 쪽 번호와 문항 번호가 처음부터 끝까지 이어진다.
#import "cover.typ": cover-front, cover-back
#cover-front
#counter(page).update(1)
#include "파트1/개념편.typ"
#include "파트1/문항편.typ"
#include "파트2/개념편.typ"
#include "파트2/문항편.typ"
#include "파트3/개념편.typ"
#include "파트3/문항편.typ"
#include "파트4/개념편.typ"
#include "파트4/문항편.typ"
#include "파트5/개념편.typ"
#include "파트5/문항편.typ"
#include "파트6/개념편.typ"
#include "파트6/문항편.typ"
#cover-back
