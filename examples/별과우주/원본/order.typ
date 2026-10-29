// 파트 순서와 문항 시작 번호. 앞 파트의 문항 수를 자동으로 세어 번호가 1번부터 끝까지 이어진다.
#import "파트1/content.typ" as p1
#import "파트2/content.typ" as p2
#import "파트3/content.typ" as p3
#import "파트4/content.typ" as p4
#import "파트5/content.typ" as p5
#import "파트6/content.typ" as p6
#let counts = (p1, p2, p3, p4, p5, p6).map(p => p.questions.len())
#let start-of(n) = 1 + counts.slice(0, n - 1).sum(default: 0)
