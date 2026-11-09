# 개발과 게시

[프로젝트 소개](../README.md) · [사용 안내](USAGE.md) · [임용 교재](IMYONG.md)

## 준비물

```bash
python3 scripts/check_env.py
```

점검 결과를 보고 필요한 것만 준비합니다. `--install`은 환경을 실제로 변경하므로 먼저 점검 결과를 확인합니다.

| 제작 방식 | 준비물 |
| --- | --- |
| 학교 시험지·Typst 학습지 | Typst 0.13 이상, Python 3, PyMuPDF·openpyxl, 본문 글꼴 |
| 임용 원문 문제편 | Python 3, [requirements-imyong.txt](../requirements-imyong.txt)의 PyMuPDF |

임용용 가상환경은 다음과 같이 준비합니다. Windows에서는 가상환경의 Python을 직접 실행해도 됩니다.

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-imyong.txt
# Windows:
# .venv\Scripts\python.exe -m pip install -r requirements-imyong.txt
```

학교 교재는 KoPub 바탕이 없으면 Noto Serif KR·Windows 바탕 등 대체 글꼴을 사용합니다. 제목 글꼴 Pretendard는 저장소에 포함합니다. 임용 원문 글꼴은 그대로 재사용하며 머리말용 한글 글꼴은 별도로 선택합니다. 실제 Windows 제작 전 과정은 아직 검증하지 않았습니다.

## 설문을 로컬에서 보기

```bash
python3 -m http.server 8769 --bind 127.0.0.1
```

- 학교 시험지·학습지: `http://127.0.0.1:8769/survey/`
- 임용: `http://127.0.0.1:8769/survey/?source=imyong`

설문과 제작 요청은 브라우저에서 동작합니다. 공개 원본 PDF·검색 색인·교재 다운로드에는 네트워크가 필요합니다.

## 임용 패널 수정

직접 수정할 원본은 `survey/imyong-panel.html`, 공통 선택 로직은 `survey/imyong-topics.mjs`, 분류표는 `data/imyong-topics.json`입니다. `survey/index.html`에 포함되는 임용 패널은 생성물입니다.

```bash
python3 scripts/build_survey_imyong.py
python3 -m unittest discover -s scripts -p test_imyong.py
```

재생성 뒤 원본과 `survey/index.html`을 함께 커밋합니다. 범위 변경 후 일치 수·예시·제작 JSON이 같은 문항을 선택하는지, 기존 요청이 무효화되는지, 새로고침으로 설정이 복원되는지 확인합니다. 기존 학교 시험지·학습지 경로도 확인합니다.

## 색인·원문 합성

- 임용 원문 색인: `data/imyong-questions.json.gz`
- 분류·배점·선택 로직: `scripts/imyong_data.py`
- PDF 원문 합성: `scripts/build_imyong_book.py`
- 원문·출처·배점·주제를 기출 탐색기와 동기화: `scripts/sync_imyong.py`

동기화는 **print와 기출 탐색기 두 작업 사본의 생성물을 변경**하므로 각각 별도 브랜치를 준비하고 변경을 함께 검토합니다.

```bash
python3 scripts/sync_imyong.py --library /path/to/exam-search
```

동기화 뒤 기출 탐색기의 브라우저용 색인 생성과 관련 검사를 실행합니다. 원문 PDF는 가져온 바이트의 SHA-256을 확인하고, 완성 PDF는 누락·중복·배점별 배치·원문 영역·확대본 연결을 검사합니다. 표지·2점·4점·긴 문항·마지막 쪽을 실제로 렌더링해 읽습니다. 원문 합성이 해설 생성까지 수행한다고 안내하지 않습니다.

## 코드와 게시 화면의 관계

print 저장소는 설문 원본과 도구를 관리합니다. **print 저장소에 푸시하는 것만으로 `5e.ai.kr/print`가 바뀌지는 않습니다.**

1. print에서 `survey/index.html`을 재생성하고 검수합니다.
2. [5E 저장소](https://github.com/seungyeon980808-pixel/5E)의 별도 작업 브랜치에 같은 내용을 `print/index.html`로 반영합니다.
3. 5E의 `node --test desktop/print-publication.test.cjs`와 필수 검사를 통과한 변경을 병합합니다.
4. 기존 [Print Route 워크플로](https://github.com/seungyeon980808-pixel/5E/blob/main/.github/workflows/print-route.yml)를 사용합니다. `base_run`은 현재 게시된 **최신 성공 Pages 게시 실행**이어야 합니다. 예전 실행 번호를 고정해서 재사용하지 않습니다.
5. 게시 완료 후 공개 HTML과 반영한 문서를 대조하고, 실제 조건 선택·제작 요청·다운로드·기존 경로를 확인합니다.

Print Route는 게시 기록의 해시로 현재 사이트를 확인하고 print 문서만 바꾸는 절차입니다. 본체를 함께 배포하는 절차로 대체하지 않습니다. 문서만 고칠 때는 설문 재생성·화면 배포·앱 버전 변경이 필요하지 않습니다.

버전 파일·태그·교재 판 구분은 [5E 저장소 구성과 버전](https://github.com/seungyeon980808-pixel/exam-search/blob/main/docs/REPOSITORIES.md)을 따릅니다.
