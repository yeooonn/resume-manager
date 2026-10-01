---
name: resume-base
description: 3년차 프론트엔드 개발자의 차별화된 기본 이력서를 생성한다. 인터뷰어와 커밋 분석을 병렬 실행해 profile.md를 만들고, 작가 1명 + 비평가 3명을 거쳐 이력서를 작성한다. 기존 profile이 있으면 업데이트 모드로 시작한다.
---

## Usage
```
/resume-base
```

## Pipeline

### Phase 1 — 데이터 수집 (병렬)
- Track A: `interviewer` → sources/profile.md (draft). 기존 profile.md 있으면 resume-at 주석 읽어 재개.
- Track B: `commit-analyzer` → sources/commits.json.

### Phase 2 — 통합
- `profile-integrator`가 profile.md와 commits.json 대조.
- 불일치는 주석(`<!-- 커밋 근거 있음 -->`, `<!-- 근거 없음 -->`)으로 표시.
- 사용자에게 "주석을 확인한 뒤 다음 단계로 진행하시겠어요?"를 묻고 응답 대기.

### Phase 3 — 이력서 작성 (최대 3라운드)
- `resume-writer`(mode=base) 초안 작성.
- `fact-checker`, `cliche-detector`, `differentiation-validator`가 **병렬 호출**.
- CRITICAL 발견 시 재작성. 최대 3라운드.
- 3라운드 초과 시 "프로필 보강 필요: [프로젝트 목록]" 리포트.

### Phase 4 — 저장
- `resumes/이력서_기본.md`에 저장. 종료.

## 사실 불변 원칙
어느 단계에서도 profile.md에 없는 회사·수치·기술은 이력서에 등장할 수 없다. `fact-checker`가 위반 즉시 중단.

## 중단·재개
- 인터뷰 중 사용자 "여기까지" → profile.md에 resume-at 주석 남기고 종료.
- 재실행 시 자동 재개.
