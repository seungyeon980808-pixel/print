// 문항표(엑셀)용 자료 뽑기: typst query 문항표.typ "<rows>" --field value  (만들기.sh가 씀)
#import "문항.typ": questions
#let marks = ("①", "②", "③", "④", "⑤")
#let w(s) = if s.match(regex("^[A-Za-z0-9.]+$")) != none { s } else { "(" + s + ")" }
// 내용(수식 포함)을 글자로: 분수 a/b, 첨자 x_A, 거듭제곱 x^2, 제곱근 √(…)
#let tx(c) = {
  if c == none { "" }
  else if type(c) == str { c }
  else if type(c) in (int, float) { str(c) }
  else if c.func() == math.frac { w(tx(c.num)) + "/" + w(tx(c.denom)) }
  else if c.func() == math.attach {
    tx(c.base) + if c.has("b") and c.b != none { "_" + tx(c.b) } else { "" } + if c.has("t") and c.t != none { "^" + tx(c.t) } else { "" }
  }
  else if c.func() == math.root { "√" + w(tx(c.radicand)) }
  else if c.func() == super { "^" + tx(c.body) }
  else if c.func() == sub { "_" + tx(c.body) }
  else if c.func() == linebreak or c.func() == parbreak { " " }
  else if c.has("text") { if type(c.text) == str { c.text } else { tx(c.text) } }
  else if c.has("children") { c.children.map(tx).join() }
  else if c.has("body") { tx(c.body) }
  else if c.func() == [ ].func() { " " }
  else if c.has("child") { tx(c.child) }
  else { "" }
}
#metadata(questions.map(q => (
  no: q.no, std: q.std, level: q.level, change: q.change, src: q.src, source: q.source,
  form: q.form, data: q.data, calc: if q.calc { "계산" } else { "비계산" },
  answer: marks.at(q.answer - 1), points: q.points,
  lead: tx(q.lead), ask: tx(q.ask),
  bogi: if "bogi" in q { q.bogi.enumerate().map(((i, b)) => ("ㄱ", "ㄴ", "ㄷ", "ㄹ").at(i) + ". " + tx(b)).join("\n") } else { "" },
  choices: q.choices.map(tx),
  explain: if type(q.explain) == array { q.explain.map(tx).join("\n") } else { tx(q.explain) },
  figs: q.figs,
  orig: q.at("orig", default: ""), how: q.at("how", default: ()).join("\n"),
))) <rows>
