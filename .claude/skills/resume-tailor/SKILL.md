---
name: resume-tailor
description: 채용공고 URL을 받아 profile.md에서 공고 맞춤 이력서를 새로 생성한다. 강도(강/중/약)를 사용자에게 묻고, 사실은 왜곡하지 않으면서 강조·순서·헤드라인만 조정한다.
---

## Usage
```
/resume-tailor <URL>
/resume-tailor <URL> --refresh
```

## Pipeline

### Phase 1 — 공고 수집
- `job-parser` 호출: URL → WebFetch 시도 → 실패 시 사용자 텍스트 요청 → `resumes/jobs/<회사>_<yyyy-mm-dd>.md` 저장.
- 같은 날짜 파일 존재 시:
  > "resumes/jobs/<파일>이 이미 있습니다. (1) 기존 사용 (2) 새로 가져오기(--refresh) — 선택해주세요."
- 응답 대기 후 분기.

### Phase 2 — 강도 선택
- 사용자에게: "맞춤 강도를 선택해주세요: 강(재구성) / 중(순서+헤드라인) / 약(단어만)"

### Phase 3 — 매핑
- `job-relevance-mapper` 호출 → relevance-map (텍스트).

### Phase 4 — 이력서 작성 (최대 3라운드)
- `resume-writer`(mode=tailor_strong/medium/light) 초안 작성.
- 병렬 비평: `fact-checker`, `cliche-detector`, `job-alignment-validator`.
- CRITICAL 발견 시 재작성.
- `unmatched_must`는 이력서에 반영하지 않고 별도 리포트 보관.

### Phase 5 — 저장 + 리포트
- `resumes/tailored/<회사>_<yyyy-mm-dd>.md` 저장.
- "다음 must 요건은 profile 근거가 없어 반영되지 않았습니다: [목록]" 출력.

## 사실 불변 원칙
강도 "강"에서도 profile.md에 없는 사실은 절대 등장하지 않는다.
