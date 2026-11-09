"""원문 PDF를 벡터로 합성한 임용 학습교재. 2점=4문항/쪽, 4점=2문항/쪽.
예: python3 scripts/build_imyong_book.py --subject t_physics --output 물리.pdf --source-root 공유폴더
의존성: pymupdf. 원본·이미지는 수정하지 않는다. --source-root 생략 시 공개 게이트웨이에서 읽는다.
"""
import argparse, hashlib, json, math, subprocess, tempfile
from pathlib import Path
from urllib.parse import quote
import pymupdf as fitz
from imyong_data import load_items, select_items, load_taxonomy

BASE='https://5e-google-drive-gateway.5e-desktop.workers.dev/v1/google-drive/folders/1N46Woe4wIXs-PoUpVf0Uu4hPkSIUBqgX/public/'
SUBJECTS={'t_physics':'물리','t_chemistry':'화학','t_biology':'생물','t_earth':'지구과학'}

def dimensions(q):
    boxes=[r.get('displayBox',r['box']) for r in q['regions']]
    return max(b[2]-b[0] for b in boxes),sum(b[3]-b[1] for b in boxes)+7*(len(boxes)-1)

def flow_parts(q, doc, width, height, max_scale=1):
    """원래 시험지에서 이미 이어지는 영역 사이에서만 단을 나눈다. 글줄·그림은 자르지 않는다."""
    parts=[{'page':r['page'],'box':list(r.get('displayBox',r['box']))} for r in q['regions']]
    qw,qh=dimensions(q);one=min(width/qw,height/qh,max_scale)
    if one>=.92 or len(parts)<2:return one,[parts]
    def part_height(group):
        return sum(fitz.Rect(p['box']).height for p in group)+7*(len(group)-1)
    cut=min(range(1,len(parts)),key=lambda i:max(part_height(parts[:i]),part_height(parts[i:])))
    left,right=parts[:cut],parts[cut:]
    two=min(((width-12)/2)/qw,height/max(part_height(left),part_height(right)),max_scale)
    return (two,[left,right]) if two>one*1.08 else (one,[parts])

def build(args):
    data=load_items();files={f['pdfFile']:f for f in data['files']}
    items=select_items(data['items'],args.subject,(args.year_from,args.year_to),args.domain,args.keywords,args.points,args.topic_ids,args.exclude_keywords,args.paper_part,args.question_limit,args.sort_mode,args.seed)
    if not items: raise ValueError('조건에 맞는 2점·4점 문항이 없습니다.')
    if args.output.exists() and not args.overwrite: raise FileExistsError('기존 판을 보존합니다. 새 버전 이름을 쓰거나 작업 중 초안에만 --overwrite를 쓰세요.')
    w,h={'B4':(728.5,1031.8),'A4':(595.28,841.89),'A3':(1190.55,841.89)}[args.paper]
    out=fitz.open();docs={};manifest=[];cache=args.cache
    candidates=[args.font,Path('/System/Library/Fonts/Supplemental/Arial Unicode.ttf'),Path('C:/Windows/Fonts/malgun.ttf'),Path('/usr/share/fonts/truetype/nanum/NanumGothic.ttf')]
    font_path=next((p for p in candidates if p and p.is_file()),None)
    meta_font=fitz.Font(fontfile=str(font_path)) if font_path else fitz.Font('korea')
    cache.mkdir(parents=True,exist_ok=True)
    def text(page,pos,value,size=10,color=(.10,.19,.23)):
        # 원문 PDF의 Dotum 리소스와 충돌하지 않는 별도 글꼴 이름을 쓴다.
        page.insert_font(fontname='F5EBookMeta',fontbuffer=meta_font.buffer)
        page.insert_text(pos,value,fontsize=size,fontname='F5EBookMeta',color=color)
    label=args.title or ('과학교육론' if args.domain=='pedagogy' else '·'.join(SUBJECTS[s] for s in args.subject) if args.subject else '과학 4과목')
    cover=out.new_page(width=w,height=h)
    text(cover,(42,80),'5E  임용 기출 학습교재',16)
    text(cover,(42,150),label,min(29,(w-84)/max(meta_font.text_length(label,fontsize=1),1)))
    text(cover,(42,192),f'{args.year_from}–{args.year_to}학년도 · 2점 / 4점 · 원문 수록',13)
    cover.draw_line((42,219),(w-42,219),color=(.12,.34,.37),width=1)
    order_label={'recent':'최신 학년도순','oldest':'오래된 학년도순','topic':'주제별','random':'무작위'}[args.sort_mode]
    lines=[f'2점: 한 쪽에 4문항  |  4점: 한 쪽에 2문항  |  {args.paper}',f'수록 문항 {len(items):,}개 · {order_label} · 배점별 분리','풀이 완료 □    다시 풀기 □    풀이 날짜: __________','원문 수식·그림·발문을 그대로 유지했습니다.','긴 문항은 원래 시험지의 이어지는 영역을 오른쪽 단으로 연결했습니다.','배점이 확인되는 문항만 수록하며, 총배점과 소문항 배점을 구분합니다.','각 배점 마지막 쪽의 남은 칸은 풀이 공간으로 둡니다.','과학교육론·단원·세부 주제는 원문 용어에 따른 자동 분류입니다.','문제편입니다. 정답·해설은 검토가 끝난 뒤 별도 판에 추가합니다.','출처: 한국교육과정평가원 공개 중등 임용시험 문제','제작 도구 v1.1.0 · 자료판 imyong-2002-2026-v1']
    for i,line in enumerate(lines):text(cover,(42,270+i*29),line,11)
    if args.keywords:text(cover,(42,600),f'검색어: {args.keywords}',11)
    toc=[];seq=0
    header_label=label
    while meta_font.text_length(header_label,fontsize=10)>w*.5:header_label=header_label[:-2]+'…'
    for points,per in [(2,4),(4,2)]:
        group=[q for q in items if q['points']==points]
        if not group:continue
        toc.append([1,f'{points}점 · {len(group)}문항 · 한 쪽 {per}문항',len(out)+1])
        for start in range(0,len(group),per):
            page=out.new_page(width=w,height=h);pno=len(out)
            text(page,(32,28),f'{header_label} · {points}점 학습  /  {args.year_from}–{args.year_to}학년도',10)
            text(page,(w-90,h-20),f'{pno} / 5E',9)
            cols=4 if args.paper=='A3' and per==4 else 2
            rows=math.ceil(per/cols);gap=16;cw=(w-64-gap*(cols-1))/cols;ch=(h-86-gap*(rows-1))/rows
            for j,q in enumerate(group[start:start+per]):
                seq+=1;col=j%cols;row=j//cols;x=32+col*(cw+gap);y=48+row*(ch+gap)
                text(page,(x,y+10),f'{seq:03}  {q["year"]} {q["subjectLabel"]} {q["paper"] if q["paper"]!="single" else ""} · 원문 {q["no"]}번',9)
                text(page,(x,y+26),f'{points}점  □ 완료  □ 다시 풀기',8)
                page.draw_line((x,y+33),(x+cw,y+33),color=(.67,.72,.73),width=.4)
                name=q['pdfFile'];f=files[name]
                if name not in docs:
                    source=args.source_root/f['publicPath'] if args.source_root else cache/name
                    if not source.exists():
                        url=BASE+'/'.join(quote(s,safe='') for s in f['publicPath'].split('/'))
                        subprocess.run(['curl','--fail','--location','--retry','3','--max-time','90','-H','Origin: https://www.5e.ai.kr','-A','Mozilla/5.0','-o',str(source),url],check=True,capture_output=True)
                    if hashlib.sha256(source.read_bytes()).hexdigest()!=f['sha256']:raise ValueError(f'원본 해시가 다릅니다: {source}')
                    docs[name]=fitz.open(source)
                scale,columns=flow_parts(q,docs[name],cw,ch-51,.80 if args.paper=='A3' else 1)
                if len(columns)>1:
                    hint='왼쪽 단 → 오른쪽 단';text(page,(x+cw-meta_font.text_length(hint,fontsize=8),y+26),hint,8)
                if scale<args.min_scale:
                    hint='작은 글씨: 원문 확대본 참조';text(page,(x+cw-meta_font.text_length(hint,fontsize=7),y+37),hint,7)
                for ci,parts in enumerate(columns):
                    top=y+42;cx=x+ci*((cw+12)/2)
                    for r in parts:
                        box=fitz.Rect(r['box']);target=fitz.Rect(cx,top,cx+box.width*scale,top+box.height*scale)
                        page.show_pdf_page(target,docs[name],r['page']-1,clip=box)
                        top+=box.height*scale+7*scale
                bottom=y+42+max(sum(fitz.Rect(p['box']).height for p in parts)+7*(len(parts)-1) for parts in columns)*scale
                if args.memo_style!='blank':
                    top=bottom+18;end=y+ch-8
                    if end-top>28:
                        for line_y in range(math.ceil(top),math.floor(end),14):page.draw_line((x,line_y),(x+cw,line_y),color=(.84,.86,.87),width=.25)
                        if args.memo_style=='grid':
                            for line_x in range(math.ceil(x),math.floor(x+cw)+1,14):page.draw_line((line_x,top),(line_x,end),color=(.84,.86,.87),width=.25)
                # 원문 아래의 여백을 풀이 공간으로 남긴다.
                manifest.append({k:q.get(k) for k in ['id','subject','subjectLabel','year','paper','no','domain','points','pointsEvidence','pdfFile','sourceUrl','text','topicIds','topicEvidence']}|{'book':args.output.name,'bookPage':pno,'slot':j+1,'scale':round(scale,4),'questionOrder':seq,'sourcePages':sorted(set(r['page'] for r in q['regions'])),'columns':columns})
    out.set_toc(toc);out.set_metadata({'title':f'{label} 임용 기출 학습교재','author':'5E','subject':'한국교육과정평가원 공개 기출 · 원문 2점 4문항/쪽, 4점 2문항/쪽','keywords':'임용,과학교육론,학습,기출','creator':'5E print v1.1.0'})
    args.output.parent.mkdir(parents=True,exist_ok=True)
    out.subset_fonts();out.save(args.output,garbage=4,deflate=True)
    enlarged=fitz.open();seen={}
    long_items=[m for m in manifest if m['scale']<args.min_scale]
    for m in long_items:
        pages=[]
        for p in m['sourcePages']:
            key=(m['pdfFile'],p)
            if key not in seen:
                enlarged.insert_pdf(docs[m['pdfFile']],from_page=p-1,to_page=p-1)
                seen[key]=len(enlarged)
            pages.append(seen[key])
        m['enlargedPages']=pages
    reference=args.output.with_name(args.output.stem+'_원문확대본.pdf')
    if len(enlarged):
        if reference.exists() and not args.overwrite:raise FileExistsError(reference)
        enlarged.set_metadata({'title':f'{label} 임용 기출 원문 확대본','author':'한국교육과정평가원 / 5E','subject':'본책에서 축소되는 긴 문항의 원본 시험지 쪽 모음. 문항표 enlargedPages 참조.'})
        enlarged.save(reference,garbage=4,deflate=True)
    for doc in docs.values():doc.close()
    settings={k:getattr(args,k) for k in ['subject','domain','year_from','year_to','points','topic_ids','keywords','exclude_keywords','paper_part','question_limit','sort_mode','seed','memo_style','title']}
    args.output.with_suffix('.json').write_text(json.dumps({'schema':1,'toolVersion':'1.1.0','dataVersion':data['dataVersion'],'topicVersion':data['topicVersion'],'sourceRevision':data['sourceRevision'],'settings':settings,'content':{'solutions':'not-included','concepts':'not-included'},'paper':args.paper,'perPage':{'2':4,'4':2},'enlargedFile':reference.name if len(enlarged) else None,'items':manifest},ensure_ascii=False,indent=2))
    print(json.dumps({'output':str(args.output),'questions':len(items),'pages':len(out),'minScale':min(m['scale'] for m in manifest),'bytes':args.output.stat().st_size},ensure_ascii=False))

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--subject',nargs='*',choices=SUBJECTS,default=[])
    ap.add_argument('--domain',choices=['','pedagogy','content'],default='')
    ap.add_argument('--year-from',type=int,default=2017);ap.add_argument('--year-to',type=int,default=2026)
    ap.add_argument('--keywords',default='');ap.add_argument('--points',type=int,nargs='+',choices=[2,4],default=[2,4])
    ap.add_argument('--paper',choices=['B4','A4','A3'],default='A3');ap.add_argument('--min-scale',type=float,default=.78,help='이 축소율 미만인 문항은 원문 확대본도 함께 제공')
    ap.add_argument('--title',default='');ap.add_argument('--source-root',type=Path)
    ap.add_argument('--topic-ids',nargs='*',default=[]);ap.add_argument('--exclude-keywords',default='')
    ap.add_argument('--paper-part',choices=['','A','B'],default='');ap.add_argument('--question-limit',type=int,default=0)
    ap.add_argument('--sort-mode',choices=['recent','oldest','topic','random'],default='recent');ap.add_argument('--seed',default='5e')
    ap.add_argument('--memo-style',choices=['blank','ruled','grid'],default='blank')
    ap.add_argument('--font',type=Path,help='교재 머리말용 한글 TTF 글꼴. 원문 글꼴은 그대로 유지')
    ap.add_argument('--cache',type=Path,default=Path(tempfile.gettempdir())/'5e-print-imyong')
    ap.add_argument('--output',type=Path,required=True);ap.add_argument('--overwrite',action='store_true')
    ap.add_argument('--config',type=Path,help='print 설문에서 받은 설정 JSON')
    initial,_=ap.parse_known_args()
    if initial.config:
        config=json.loads(initial.config.read_text())
        mapping={'yearFrom':'year_from','yearTo':'year_to','subject':'subject','domain':'domain','points':'points','paper':'paper','keywords':'keywords','topicIds':'topic_ids','excludeKeywords':'exclude_keywords','paperPart':'paper_part','questionLimit':'question_limit','sortMode':'sort_mode','seed':'seed','memoStyle':'memo_style','title':'title'}
        ap.set_defaults(**{dest:config[key] for key,dest in mapping.items() if key in config})
    args=ap.parse_args()
    if any(s not in SUBJECTS for s in args.subject) or any(p not in (2,4) for p in args.points) or args.paper not in ('B4','A4','A3') or args.domain not in ('','content','pedagogy'):
        ap.error('지원하지 않는 과목·배점·용지·영역 설정입니다.')
    allowed={t['id'] for u in load_taxonomy()['units'] for t in u['topics']}
    if any(t not in allowed for t in args.topic_ids) or args.paper_part not in ('','A','B') or args.memo_style not in ('blank','ruled','grid') or not 0<=args.question_limit<=2588:
        ap.error('주제·문항 수·전공 구분·여백 설정을 확인하세요.')
    build(args)
