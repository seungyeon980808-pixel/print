"""공개 임용 원문 색인. 총배점만 판별하고 소문항 배점을 더하지 않는다."""
import gzip, json, re, unicodedata
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / 'data' / 'imyong-questions.json.gz'
TOPICS = DATA.with_name('imyong-topics.json')

def normalized(text):
    return re.sub(r'\s+', '', unicodedata.normalize('NFKC', text).lower())

def search_text(q):
    return normalized(' '.join([q.get('title', ''), q.get('text', ''), *q.get('tags', [])]))

def load_taxonomy():
    return json.loads(TOPICS.read_text())

def classify_topics(q, taxonomy):
    text = normalized(q.get('questionText', q.get('text', '')))
    ids, evidence = [], {}
    subjects = [q['subject']] + (['pedagogy'] if q['domain'] == 'pedagogy' else [])
    for subject in subjects:
        found = []
        for unit in taxonomy['units']:
            if unit['subject'] != subject:
                continue
            for topic in unit['topics']:
                matches = [k for k in topic['keywords'] if normalized(k) in text]
                if matches:
                    found.append(topic['id']);evidence[topic['id']] = matches[:3]
        ids.extend(found or [subject + '.other.unclassified'])
    return ids, evidence

def stable_hash(value):
    value_hash = 2166136261
    for byte in value.encode('utf-8'):
        value_hash = ((value_hash ^ byte) * 16777619) & 0xffffffff
    return value_hash

def extract_points(text):
    text = unicodedata.normalize('NFKC', text)
    total = re.search(r'총\s*(\d+(?:\.\d+)?)\s*점', text)
    brackets = re.findall(r'[\[【]\s*(\d+(?:\.\d+)?)\s*점\s*[\]】]', text)
    # 구형 시험지는 괄호 속 총점 1회만 있는 경우도 있다. 복수의 소배점은 추정하지 않는다.
    parens = re.findall(r'\(\s*(\d+(?:\.\d+)?)\s*점\s*\)', text)
    if total:
        return float(total[1]), total[0]
    if brackets:
        return float(brackets[0]), f'[{brackets[0]}점]'
    if len(parens) == 1:
        return float(parens[0]), f'({parens[0]}점)'
    return None, ''

def load_items():
    with gzip.open(DATA, 'rt', encoding='utf-8') as f:
        return json.load(f)

def select_items(items, subjects=(), years=(2002, 2026), domain='', keywords='', points=(2, 4), topic_ids=(), exclude_keywords='', paper_part='', limit=0, sort_mode='recent', seed='5e'):
    tokens = re.split(r'[\s,，#]+', unicodedata.normalize('NFKC', keywords).lower().strip())
    tokens = [t for t in tokens if t]
    if len(tokens) > 3:
        raise ValueError('검색어는 세 단어까지 입력하세요.')
    if years[0] > years[1]:
        raise ValueError('시작 학년도는 끝 학년도 이하여야 합니다.')
    if sort_mode not in ('recent', 'oldest', 'topic', 'random') or not isinstance(limit, int) or limit < 0:
        raise ValueError('문항 수와 정렬 설정을 확인하세요.')
    excluded = [normalized(t) for t in re.split(r'[\s,，#]+', exclude_keywords) if t]
    selected = [q for q in items if (not subjects or q['subject'] in subjects)
        and years[0] <= q['year'] <= years[1]
        and (not domain or q['domain'] == domain)
        and (not points or q.get('points') in points)
        and (not topic_ids or set(topic_ids).intersection(q.get('topicIds', [])))
        and (not paper_part or q['paper'] == paper_part)
        and not any(t in search_text(q) for t in excluded)
        and all(t in search_text(q) for t in tokens)]
    def key(q):
        base = (q['year'] if sort_mode == 'oldest' else -q['year'], q['subject'], q['paper'], q['order'])
        if sort_mode == 'random':return (stable_hash(seed + '\0' + q['id']), q['id'])
        if sort_mode == 'topic':return (next((t for t in q.get('topicIds', []) if not topic_ids or t in topic_ids), ''), *base)
        return base
    selected.sort(key=key)
    if limit:selected = selected[:limit]
    return sorted(selected, key=lambda q: (q.get('points') or 99, *key(q)))
