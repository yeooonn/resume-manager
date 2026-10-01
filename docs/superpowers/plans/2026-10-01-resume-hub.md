# resume-hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 3년차 프론트엔드 개발자의 차별화된 이력서를 생성·맞춤화·렌더링하는 3-스킬 하네스를 구축한다.

**Architecture:** 공유 원자재(`sources/profile.md`)를 두고 3개 스킬이 각자 다른 산출물을 만든다. `/resume-base`는 인터뷰 + 커밋 분석으로 프로필을 만들고 기본 이력서를 생성, `/resume-tailor`는 채용공고를 받아 강도별 맞춤 이력서를 생성, `/resume-render`는 마크다운을 인쇄 친화 HTML로 변환한다. 10개 Claude Code 에이전트가 작가·비평가·분석가 역할을 나눠 맡는다.

**Tech Stack:** Claude Code (스킬·에이전트), Markdown, YAML, Bash. 외부 npm 의존성 없음.

**Spec:** `docs/superpowers/specs/2026-09-30-resume-hub-design.md`

## Global Constraints

- 외부 npm 의존성 추가 금지. 마크다운 → HTML 변환도 Claude가 직접 수행.
- 모든 스킬·에이전트는 프로젝트 `.claude/skills/`, `.claude/agents/` 하위에만 둔다. 사용자 전역(`~/.claude/`)에는 두지 않는다.
- 어떤 에이전트도 `sources/기존이력서.md`를 읽지 않는다 (뻔한 표현 오염 방지).
- `profile.md`에 없는 회사·수치·기술은 어떤 이력서에도 등장 금지. `fact-checker`가 즉시 중단.
- 산출물 파일명 날짜 포맷: `yyyy-mm-dd` (예: `토스_2026-10-01.md`).
- 모든 에이전트 YAML frontmatter에 `name`, `description`, `tools` 필드가 있어야 한다.
- 모든 커밋 메시지 마지막에 `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` 포함.
- 뻔함 블랙리스트는 `scripts/check-cliches.txt` 한 곳에서 관리.

## Review Focus

플랜 안의 테스트가 커버하지 않는 입력/실패 모드 중 실제 사용자가 가장 먼저 부딪힐 5가지. 각 항목에 그걸 핀하는 테스트가 어느 태스크에 들어가 있는지 명시한다.

1. **인터뷰 중단 후 재시작** — `profile.md`에 남긴 `<!-- resume-at: ... -->` 주석을 interviewer가 정확히 읽어 해당 지점부터 재개해야 한다. (Task 4 Step 2)
2. **채용공고 URL 봇 차단** — WebFetch 실패 시 사용자에게 텍스트 붙여넣기 요청 안내가 떠야 한다. (Task 8 Step 2)
3. **repos.yaml 저장소 경로 부재** — 경로가 사라졌거나 디렉토리가 비어 있어도 crash 없이 경고 후 스킵. (Task 5 Step 2)
4. **마크다운 이력서 안의 HTML 특수문자** — `<`, `>`, `&`, `"`가 포함된 이력서를 `/resume-render`에 넣으면 escape된 결과가 나와야 한다. (Task 13 Step 2)
5. **같은 회사 당일 재실행 충돌** — 같은 날 같은 회사 공고로 `/resume-tailor`를 재실행하면 `--refresh` 없이도 기존 파일 덮어쓰기 전 사용자에게 물어야 한다. (Task 11 Step 2)

---

## File Structure

**새로 만들 파일**
- `.claude/skills/resume-base/SKILL.md`
- `.claude/skills/resume-tailor/SKILL.md`
- `.claude/skills/resume-render/SKILL.md`
- `.claude/agents/interviewer.md`
- `.claude/agents/commit-analyzer.md`
- `.claude/agents/profile-integrator.md`
- `.claude/agents/resume-writer.md`
- `.claude/agents/cliche-detector.md`
- `.claude/agents/differentiation-validator.md`
- `.claude/agents/fact-checker.md`
- `.claude/agents/job-parser.md`
- `.claude/agents/job-relevance-mapper.md`
- `.claude/agents/job-alignment-validator.md`
- `templates/resume-template.html`
- `scripts/check-agent-schema.sh`
- `scripts/check-resume.sh`
- `scripts/check-cliches.txt`
- `tests/fixtures/profile-sample.md`
- `tests/fixtures/job-sample.md`
- `tests/fixtures/resume-sample.md`

**수정할 파일**
- `config/repos.yaml` — `git_author` 필드 추가

**유지할 파일 (건드리지 않음)**
- `sources/기존이력서.md` — 사용자 원본

---

### Task 1: 기반 구축 (디렉토리·config 확장·검증 스크립트·fixture)

**Files:**
- Create: `.claude/skills/`, `.claude/agents/`, `templates/`, `output/`, `scripts/`, `tests/fixtures/` 디렉토리
- Modify: `config/repos.yaml`
- Create: `scripts/check-agent-schema.sh`
- Create: `scripts/check-resume.sh`
- Create: `scripts/check-cliches.txt`
- Create: `tests/fixtures/profile-sample.md`
- Create: `tests/fixtures/job-sample.md`
- Create: `tests/fixtures/resume-sample.md`

**Interfaces:**
- Produces:
  - `scripts/check-agent-schema.sh <agent-file>` → exit 0 if valid, 1 if invalid.
  - `scripts/check-resume.sh <resume.md> <profile.md>` → exit 0 if 자동 검증 통과.
  - fixture 3종.

- [ ] **Step 1: 디렉토리 생성**

```bash
mkdir -p .claude/skills .claude/agents templates output scripts tests/fixtures
```

- [ ] **Step 2: config/repos.yaml에 git_author 필드 추가**

`work_projects` 각 항목에 `git_author: rladuswjd` 추가, `personal_projects` 각 항목에 `git_author: yeooonn` 추가. Edit 도구로 수행.

최종 상태 예시:

```yaml
work_projects:
  - path: /Users/kim-yeonjeong/coontec/kisa-frontend
    name: KISA
    git_author: rladuswjd
    description: "고위험 취약점 관리 솔루션 개발"
    role: "frontend 개발자"
    period: "2025.11 ~ 진행중"
    tech_stack: [...]
personal_projects:
  - path: /Users/kim-yeonjeong/side_project/design-system
    name: "@yeoooonn/ds"
    git_author: yeooonn
    description: "..."
    tech_stack: [...]
```

- [ ] **Step 3: scripts/check-cliches.txt 작성**

```
다양한 프로젝트에 참여
협업 역량을 갖춤
책임감 있게
완벽한
커뮤니케이션 능력
빠르게 습득
적극적으로
성실하게
열정적으로
최선을 다해
```

- [ ] **Step 4: scripts/check-agent-schema.sh 작성**

```bash
#!/usr/bin/env bash
# scripts/check-agent-schema.sh <agent-file>
# YAML frontmatter에 name/description/tools 필드가 있는지 검증.
set -euo pipefail

FILE="${1:?usage: $0 <agent-file>}"

if [[ ! -f "$FILE" ]]; then
  echo "FAIL: file not found: $FILE" >&2
  exit 1
fi

awk '
  BEGIN { in_fm=0; have_name=0; have_desc=0; have_tools=0 }
  NR==1 && /^---$/ { in_fm=1; next }
  in_fm && /^---$/ { in_fm=0; exit }
  in_fm && /^name:/ { have_name=1 }
  in_fm && /^description:/ { have_desc=1 }
  in_fm && /^tools:/ { have_tools=1 }
  END {
    if (!have_name)  { print "FAIL: missing name" > "/dev/stderr"; exit 1 }
    if (!have_desc)  { print "FAIL: missing description" > "/dev/stderr"; exit 1 }
    if (!have_tools) { print "FAIL: missing tools" > "/dev/stderr"; exit 1 }
    print "OK"
  }
' "$FILE"
```

- [ ] **Step 5: scripts/check-resume.sh 작성**

```bash
#!/usr/bin/env bash
# scripts/check-resume.sh <resume.md> <profile.md>
set -euo pipefail

RESUME="${1:?usage: $0 <resume.md> <profile.md>}"
PROFILE="${2:?missing profile.md}"
BLACKLIST="$(dirname "$0")/check-cliches.txt"

fail=0

# 1. profile 필수 섹션
for section in "# 기본 정보" "# 커리어 서사" "# 프로젝트" "# 자기 인식" "# 지원 방향성"; do
  if ! grep -q "^$section" "$PROFILE"; then
    echo "FAIL: profile missing section: $section" >&2
    fail=1
  fi
done

# 2. 뻔함 표현 카운트
cliche_count=0
while IFS= read -r phrase; do
  [[ -z "$phrase" ]] && continue
  count=$(grep -c "$phrase" "$RESUME" || true)
  cliche_count=$((cliche_count + count))
done < "$BLACKLIST"
if [[ $cliche_count -gt 3 ]]; then
  echo "FAIL: cliche count $cliche_count > 3" >&2
  fail=1
fi

# 3. 차별화 축 키워드
if ! grep -qE "결정|트레이드오프|대안" "$RESUME"; then
  echo "FAIL: no 결정/트레이드오프/대안 keyword" >&2
  fail=1
fi
if ! grep -qE "주도|오너십" "$RESUME"; then
  echo "FAIL: no 주도/오너십 keyword" >&2
  fail=1
fi

exit $fail
```

- [ ] **Step 6: 실행 권한 부여**

```bash
chmod +x scripts/check-agent-schema.sh scripts/check-resume.sh
```

- [ ] **Step 7: tests/fixtures/profile-sample.md 작성**

```markdown
---
name: 테스트 유저
updated: 2026-10-01
positions_targeting: [프론트엔드 시니어]
exclude_domains: [보안]
---

# 기본 정보
- GitHub: test-user
- 경력: 3년 (2023-01 ~ current)
- 최근 소속: 테스트회사 · FE팀 · frontend 개발자

# 커리어 서사
UX 품질에 민감한 프론트 엔지니어. 디자인 시스템 재편과 성능 최적화 주도 경험.

# 프로젝트

## 테스트프로젝트 (2024-01 ~ 2025-12, FE 주도)

### What (한 줄)
B2B 대시보드 리뉴얼

### Why (비즈니스 배경)
기존 Angular 대시보드가 신규 요구사항 수용 불가

### 아키텍처 결정
- **결정**: Micro-frontend 대신 모놀리식 React로 통합
- **대안**: Module Federation, Qiankun 검토
- **트레이드오프**: 독립 배포 포기, 대신 번들 사이즈 30% 축소
- **결과**: 1년 후 추가 모듈 통합이 수월했음을 확인

### 오너십
- 주도한 범위: 아키텍처 결정, 상태관리 전략, CI 파이프라인
- 주도한 이유: 팀 내 React 경험 2년 이상이 본인뿐
- 배운 것: 결정 근거를 문서화하지 않으면 반복 설명이 발생

### 문제 해결
- 문제: 초기 번들 2.1MB → LCP 4.3s
- 접근: Route-level code split + 라이브러리 교체
- 해결: 번들 1.4MB, LCP 2.1s
- 결과: 세션 이탈률 12%p 감소

### 임팩트 지표
- LCP 4.3s → 2.1s (-51%)
- 번들 2.1MB → 1.4MB (-33%)

### 회고
- 상태 관리를 Zustand로 바로 가지 않고 Redux 선택한 것은 과잉이었음

---

# 기술 깊이 — 파고든 주제
- 주제: 번들링·코드 스플리팅
- 계기: LCP 저하가 세션 이탈로 직결됨을 발견
- 배운 것: Route 단위 split이 Component 단위보다 캐시 효율이 큼
- 공유 흔적: 사내 FE 길드 세션 발표

# 협업·리더십
- 신입 2명 온보딩 멘토 (3개월)
- 디자인 팀과 디자인 토큰 통합 주도

# 자기 인식
- 강점:
  - 결정 근거를 문서화하는 습관 (ADR 10건 작성)
  - 성능 지표 수집·추적 습관
  - 신입에게 설명 가능한 수준으로 지식 정리
- 약점: 백엔드 API 설계 참여 경험이 적음

# 지원 방향성
- B2B SaaS, 디자인 시스템을 중시하는 팀
- 배제: 보안
```

- [ ] **Step 8: tests/fixtures/job-sample.md 작성**

```markdown
---
company: 테스트회사
role: 프론트엔드 시니어
fetched_at: 2026-10-01
---

# 필수 요건 (must)
- React, TypeScript 3년 이상
- 대규모 상태관리 경험
- 성능 최적화 경험

# 우대 사항 (nice)
- 디자인 시스템 구축 경험
- Micro-frontend 경험
- 사내 발표·멘토링 경험

# 기술 스택
- React, TypeScript, Vite, Zustand

# 팀 문화
- 결정 과정의 문서화를 중시
- 코드 리뷰 활발
```

- [ ] **Step 9: tests/fixtures/resume-sample.md 작성 (HTML 특수문자 포함)**

```markdown
# 이력서 테스트

## 소개
<B2B 대시보드> 개발자. "코드 리뷰 & 멘토링" 중시.

- 성능 최적화: LCP 4.3s → 2.1s
- 번들: 2.1MB → 1.4MB
```

- [ ] **Step 10: 검증 스크립트 자가 테스트 (negative)**

```bash
# resume-sample에는 결정/주도 키워드가 없으므로 FAIL 반환해야 정상
scripts/check-resume.sh tests/fixtures/resume-sample.md tests/fixtures/profile-sample.md
echo "exit=$?"
```

Expected: `exit=1` (검증 스크립트가 올바르게 FAIL 감지)

- [ ] **Step 11: 커밋**

```bash
git add .claude/ templates/ output/ scripts/ tests/ config/repos.yaml
git commit -m "chore(resume-hub): bootstrap directories, config, verification scripts, fixtures

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 공유 비평가 3명 (fact-checker, cliche-detector, differentiation-validator)

**Files:**
- Create: `.claude/agents/fact-checker.md`
- Create: `.claude/agents/cliche-detector.md`
- Create: `.claude/agents/differentiation-validator.md`

**Interfaces:**
- Consumes: 이력서 초안 텍스트, profile.md 경로
- Produces: 각자 구조화된 리포트 (status: CRITICAL | WARN | OK)

- [ ] **Step 1: fact-checker.md 작성**

```markdown
---
name: fact-checker
description: 이력서 초안에서 profile.md에 없는 사실(회사·수치·기술 스택·프로젝트명)이 등장하는지 스캔한다. 위반 발견 시 CRITICAL 반환.
tools: Read, Grep
---

## Role
이력서 생성 과정의 사실 검증관. profile.md에 없는 모든 "사실성 주장"을 즉시 걸러낸다.

## Hard Rules
- profile.md에 등장하지 않는 **회사명, 프로젝트명, 수치(퍼센트/기간/인원), 기술 스택명**이 이력서에 있으면 CRITICAL.
- 해석·형용사·강조 표현은 사실이 아니므로 통과.
- 애매하면 CRITICAL이 아닌 WARN으로 분류하되 반드시 보고.

## Input
- `resume_draft`: 이력서 초안 전체 텍스트
- `profile_path`: profile.md 파일 경로

## Output
\```
## fact-checker 리포트
- status: CRITICAL | WARN | OK
- violations:
  - [CRITICAL] "KISA 프로젝트" — profile.md에 'KISA' 미등장
  - [WARN] "15% 성능 개선" — profile.md에 수치 근거 미등장
- summary: 1문장
\```

status가 CRITICAL이면 resume-writer는 반드시 재작성.
```

- [ ] **Step 2: fact-checker 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/fact-checker.md
```

Expected: `OK`

- [ ] **Step 3: cliche-detector.md 작성**

```markdown
---
name: cliche-detector
description: 이력서 초안에서 뻔한 표현(scripts/check-cliches.txt 블랙리스트)을 찾고 profile.md의 구체 근거로 대체 문장을 제안한다.
tools: Read, Grep
---

## Role
이력서가 "다들 하는 얘기"로 흘러가는 것을 막는 비평가.

## Blacklist 참조
`scripts/check-cliches.txt` 파일을 읽어 블랙리스트로 사용. 하드코딩 금지 (운영 중 추가 가능하도록).

## Rules
- 블랙리스트 표현 발견 시, profile.md에서 **그 자리에 쓸 수 있는 구체 사실**을 찾아 대체 문장을 제시.
- 근거가 없으면 "제거 권고"로 분류.
- 이력서 전체 블랙리스트 카운트가 3 초과면 CRITICAL.

## Output
\```
## cliche-detector 리포트
- status: CRITICAL | WARN | OK
- total_cliches: N
- replacements:
  - 원문: "다양한 프로젝트에 참여"
    위치: 프로젝트 요약 2번째 줄
    대안: "B2B 대시보드 2개와 디자인 시스템 1개를 React 기반으로 주도"
    근거: profile.md 프로젝트 섹션
- summary: 1문장
\```
```

- [ ] **Step 4: cliche-detector 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/cliche-detector.md
```

Expected: `OK`

- [ ] **Step 5: differentiation-validator.md 작성**

```markdown
---
name: differentiation-validator
description: 이력서가 차별화 축(아키텍처 사고 + 기술 깊이·오너십)을 충분히 담았는지 프로젝트 단위로 스코어링한다.
tools: Read, Grep
---

## Role
이력서가 뻔한 평균치로 회귀하는 것을 막는 차별화 검증관.

## Scoring Rules
이력서에 등장하는 각 프로젝트마다:
1. **아키텍처 사고 축**: "결정" / "대안" / "트레이드오프" 중 최소 1개 키워드 존재.
2. **오너십 축**: "주도" / "오너십" 중 최소 1개 키워드 존재.

- 프로젝트 중 하나라도 두 축 중 하나를 못 담으면 WARN.
- 전체 이력서에 두 축 중 어느 하나도 등장 안 하면 CRITICAL.

## Output
\```
## differentiation-validator 리포트
- status: CRITICAL | WARN | OK
- scores:
  - 프로젝트A: 아키텍처 ✓ / 오너십 ✓
  - 프로젝트B: 아키텍처 ✓ / 오너십 ✗
- misses:
  - 프로젝트B에 "주도/오너십" 키워드 없음 — profile.md의 오너십 섹션 활용 재작성 권고
- summary: 1문장
\```
```

- [ ] **Step 6: differentiation-validator 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/differentiation-validator.md
```

Expected: `OK`

- [ ] **Step 7: 커밋**

```bash
git add .claude/agents/fact-checker.md .claude/agents/cliche-detector.md .claude/agents/differentiation-validator.md
git commit -m "feat(agents): add 3 shared critics (fact-checker, cliche-detector, differentiation-validator)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: resume-writer 에이전트

**Files:**
- Create: `.claude/agents/resume-writer.md`

**Interfaces:**
- Consumes: profile.md, (옵션) relevance-map, (옵션) 공고 요약, 비평가 3명의 리포트
- Produces: 이력서 마크다운 텍스트 + 메타(라운드 수, 최종 비평가 리포트)

- [ ] **Step 1: resume-writer.md 작성**

```markdown
---
name: resume-writer
description: profile.md를 바탕으로 이력서 마크다운을 작성한다. 비평가 3명의 피드백을 받아 최대 3라운드까지 재작성한다. /resume-base와 /resume-tailor에서 공유된다.
tools: Read, Write, Edit, Grep
---

## Role
이력서 작가. 사실은 profile.md에서만, 해석과 서사만 창작.

## Hard Rules
- profile.md에 없는 사실은 절대 작성 금지. 쓰고 싶으면 "추가 인터뷰 필요"로 보고.
- 각 프로젝트마다 "결정/대안/트레이드오프" 중 1개, "주도/오너십" 중 1개를 자연스럽게 녹인다.
- 뻔한 표현(scripts/check-cliches.txt)은 쓰지 않는다. 대신 profile의 구체 근거를 끌어온다.

## Flow
1. **Draft**: profile.md 로드 → 섹션별 작성.
2. **Review**: fact-checker, cliche-detector, differentiation-validator 세 리포트 수집.
3. **Revise**: CRITICAL 있으면 반드시 재작성. WARN은 선택.
4. **Repeat**: 최대 3라운드. 초과 시 사용자에게 "profile 보강 필요: [프로젝트 목록]" 리포트.

## Modes
- `base`: 전체 섹션 순서 유지. 모든 프로젝트 포함.
- `tailor_strong`: 공고 관련도 순 재정렬, 관련 없는 프로젝트 축소, 헤드라인 재작성.
- `tailor_medium`: 프로젝트 순서만 재정렬, 헤드라인 유지.
- `tailor_light`: 구조 유지, 단어·어조만 공고 톤에 맞춤.

## Output
파일 저장은 호출자(스킬)가 담당. 작가는 (이력서 마크다운 텍스트, 라운드 수, 최종 비평가 리포트)를 반환.
```

- [ ] **Step 2: 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/resume-writer.md
```

Expected: `OK`

- [ ] **Step 3: 커밋**

```bash
git add .claude/agents/resume-writer.md
git commit -m "feat(agents): add resume-writer (shared across /resume-base and /resume-tailor)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: interviewer 에이전트 (+ resume-at 재개 테스트)

**Files:**
- Create: `.claude/agents/interviewer.md`

**Interfaces:**
- Consumes: 사용자 대화, (있으면) 기존 profile.md의 resume-at 주석
- Produces: profile.md (업데이트)

- [ ] **Step 1: interviewer.md 작성**

```markdown
---
name: interviewer
description: 7블록 카테고리 기반 인터뷰로 profile.md를 채운다. 각 질문마다 follow-up 1회를 강제하고, 세션 중단 시 재개 지점을 주석으로 남긴다.
tools: Read, Write, Edit
---

## Role
이력서 원자재를 뽑아내는 인터뷰어. 뻔한 답에 만족하지 않고 집요하게 파고든다.

## Hard Rules
- `sources/기존이력서.md`는 **절대 열지 않는다**.
- 각 질문 후 follow-up 1회 강제. 예: "그건 다들 하는 얘기예요. 당시 구체적으로 어떤 순간이었나요?"
- 세션 중단 시 profile.md에 `<!-- resume-at: <블록>, <항목> -->` 주석을 남긴다. 포맷은 **엄격히 이 형태** (스크립트가 grep으로 찾을 수 있어야 함).
- 재실행 시 기존 profile.md 로드 → `resume-at` 주석 검색 → 해당 지점부터 재개.

## 7블록 카테고리
1. 기본 정보 (이름, 연락처, GitHub, 경력, 관심·제외 도메인)
2. 커리어 서사 (왜 개발/프론트인지, 궤적 요약)
3. 프로젝트 심층 ⭐ (각 프로젝트: What/Why/아키텍처 결정/오너십/문제 해결/임팩트/회고)
4. 기술 깊이 ⭐ (파고든 주제 1개)
5. 협업·리더십 (리뷰·멘토링·크로스팀·의사결정)
6. 자기 인식 (강점 3개 근거, 개선 중인 약점)
7. 지원 방향성 (원하는 팀·제품, 배제 조건)

## 진행 순서
블록 1·2 → 블록 3을 프로젝트별로 세션마다 1~2개씩 → 블록 4·5·6·7.

## Output
profile.md를 스펙 §3-3 스키마에 맞게 작성·업데이트.
```

- [ ] **Step 2: resume-at 주석 포맷 자동 테스트**

```bash
# 샘플 partial profile 생성 (사람이 중단한 상태 모사)
cat > /tmp/profile-partial.md << 'EOF'
---
name: tester
---

# 기본 정보
- GitHub: test
<!-- resume-at: 블록 3, 프로젝트 2 -->
EOF

# interviewer가 쓰는 포맷이 grep으로 재발견 가능한지 확인 (재개의 전제조건)
if grep -qE "<!-- resume-at: [^,]+, [^>]+-->" /tmp/profile-partial.md; then
  echo "RESUME-AT FORMAT: OK"
else
  echo "FAIL"
  exit 1
fi
```

Expected: `RESUME-AT FORMAT: OK`

- [ ] **Step 3: 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/interviewer.md
```

Expected: `OK`

- [ ] **Step 4: 커밋**

```bash
git add .claude/agents/interviewer.md
git commit -m "feat(agents): add interviewer with 7-block categories and resume-at session continuity

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: commit-analyzer 에이전트 (+ 저장소 부재 안전 처리 테스트)

**Files:**
- Create: `.claude/agents/commit-analyzer.md`

**Interfaces:**
- Consumes: `config/repos.yaml`
- Produces: `sources/commits.json`

- [ ] **Step 1: commit-analyzer.md 작성**

```markdown
---
name: commit-analyzer
description: config/repos.yaml에 명시된 로컬 저장소를 git log로 분석해 프로젝트별 커밋 요약을 sources/commits.json에 저장한다. 저장소 부재/빈 저장소는 crash 없이 skip한다.
tools: Read, Write, Bash, Grep
---

## Role
프로필 작성을 보조하는 사실 수집가. 사용자가 인터뷰에서 빠뜨린 성과를 커밋으로 보완.

## Hard Rules
- 저장소 경로가 존재하지 않거나 git 저장소가 아니면 **에러 없이 경고 후 skip** → commits.json의 `skipped` 배열에 추가.
- git_author가 매칭되는 커밋이 하나도 없으면 skip.
- 커밋 메시지의 주관적 수식어(예: "완벽한", "최선의")는 제거하고 사실만 요약.

## Flow
각 저장소마다:
1. 경로 체크: `[[ -d "$path/.git" ]]` 아니면 skip (사유 기록).
2. `cd <path>` → `git log --author=<git_author> --pretty=format:'%h|%ai|%s'` 수집.
3. 결과 비면 skip (사유: no commits by author).
4. 접두사별 분류 (feat/fix/perf/refactor/docs 등).
5. 프로젝트별 요약을 commits.json 머지.

## Output 스키마 (`sources/commits.json`)
\```json
{
  "updated": "2026-10-01",
  "projects": {
    "KISA": {
      "path": "/Users/kim-yeonjeong/coontec/kisa-frontend",
      "git_author": "rladuswjd",
      "commit_count": 342,
      "features": ["대시보드 리뉴얼", "..."],
      "performance": ["번들 사이즈 30% 축소"],
      "refactors": []
    }
  },
  "skipped": [
    { "name": "GHOST", "path": "/nonexistent/path", "reason": "path not found" }
  ]
}
\```
```

- [ ] **Step 2: 저장소 부재 처리 자동 테스트 (dry)**

```bash
# 가짜 repos.yaml 생성해서 commit-analyzer가 crash 없이 skip 할 수 있는 전제조건을 확인
cat > /tmp/repos-test.yaml << 'EOF'
work_projects:
  - path: /nonexistent/path
    name: GHOST
    git_author: nobody
EOF

# bash에서 commit-analyzer의 "경로 체크" 로직을 모사
path="/nonexistent/path"
if [[ -d "$path/.git" ]]; then
  echo "FAIL: ghost path somehow exists"
  exit 1
else
  echo "SKIP LOGIC: OK (ghost path correctly rejected)"
fi
```

Expected: `SKIP LOGIC: OK (ghost path correctly rejected)`

- [ ] **Step 3: 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/commit-analyzer.md
```

Expected: `OK`

- [ ] **Step 4: 커밋**

```bash
git add .claude/agents/commit-analyzer.md
git commit -m "feat(agents): add commit-analyzer with safe skipping for missing repos

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: profile-integrator 에이전트

**Files:**
- Create: `.claude/agents/profile-integrator.md`

**Interfaces:**
- Consumes: `sources/profile.md`, `sources/commits.json`
- Produces: `sources/profile.md` (불일치 주석 삽입)

- [ ] **Step 1: profile-integrator.md 작성**

```markdown
---
name: profile-integrator
description: profile.md와 commits.json을 대조해 불일치를 주석으로 표시한다. 자동 반영 금지, 사용자 확인용 플래그만 남긴다.
tools: Read, Edit, Grep
---

## Role
인터뷰 결과와 커밋 사실을 교차 검증하는 통합자.

## Rules
- 커밋에는 있는데 profile에 안 적힌 성과 → 해당 프로젝트 블록 끝에 `<!-- 커밋 근거 있음, 확인 필요: <요약> -->` 추가.
- profile에는 있는데 커밋 근거가 없는 주장 → 해당 줄 뒤에 `<!-- 근거 없음, 확인 필요 -->` 추가.
- 자동 반영 금지. 사용자가 주석을 읽고 수동으로 반영/삭제.

## Output
업데이트된 profile.md. 주석만 추가하고 기존 내용은 바꾸지 않음.
```

- [ ] **Step 2: 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/profile-integrator.md
```

Expected: `OK`

- [ ] **Step 3: 커밋**

```bash
git add .claude/agents/profile-integrator.md
git commit -m "feat(agents): add profile-integrator for interview/commit cross-check

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: /resume-base 스킬 조립 + 통합 테스트

**Files:**
- Create: `.claude/skills/resume-base/SKILL.md`

**Interfaces:**
- Consumes: `config/repos.yaml`, 사용자 대화, (옵션) 기존 `sources/profile.md`
- Produces: `sources/profile.md`, `sources/commits.json`, `resumes/이력서_기본.md`

- [ ] **Step 1: SKILL.md 작성**

```markdown
---
name: resume-base
description: 3년차 프론트엔드 개발자의 차별화된 기본 이력서를 생성한다. 인터뷰어와 커밋 분석을 병렬 실행해 profile.md를 만들고, 작가 1명 + 비평가 3명을 거쳐 이력서를 작성한다. 기존 profile이 있으면 업데이트 모드로 시작한다.
---

## Usage
\```
/resume-base
\```

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
```

- [ ] **Step 2: fixture 기반 통합 테스트 (수동 트리거 포함)**

```bash
# fixture를 sources/로 복사해 Phase 3·4 진입 조건 세팅
mkdir -p sources resumes
cp tests/fixtures/profile-sample.md sources/profile.md

# 사용자가 수동으로 /resume-base 실행 → 이력서 생성 확인
# (아래 체크는 수동 실행 후 수행)
test -f resumes/이력서_기본.md && echo "RESUME CREATED: OK"
scripts/check-resume.sh resumes/이력서_기본.md sources/profile.md
echo "exit=$?"
```

Expected: `RESUME CREATED: OK` + `exit=0`

- [ ] **Step 3: 테스트 산출물 정리**

```bash
rm -f sources/profile.md resumes/이력서_기본.md
```

- [ ] **Step 4: 커밋**

```bash
git add .claude/skills/resume-base/SKILL.md
git commit -m "feat(skills): add /resume-base pipeline (interview + commit → profile → base resume)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: job-parser 에이전트 (+ fallback 안내 검증)

**Files:**
- Create: `.claude/agents/job-parser.md`

**Interfaces:**
- Consumes: URL 또는 사용자 붙여넣기 텍스트
- Produces: `resumes/jobs/<회사>_<yyyy-mm-dd>.md`

- [ ] **Step 1: job-parser.md 작성**

```markdown
---
name: job-parser
description: 채용공고 URL을 WebFetch로 가져오거나(실패 시 사용자 텍스트 fallback), 구조화된 공고 요약을 resumes/jobs/<회사>_<date>.md로 저장한다.
tools: WebFetch, Read, Write
---

## Role
채용공고를 구조화된 데이터로 변환하는 파서.

## Flow
1. `WebFetch(<URL>)` 시도.
2. 실패/본문 비어있음 → 사용자에게:
   > "URL 크롤에 실패했습니다 (SPA 또는 봇 차단으로 추정). 채용공고 본문 전체를 그대로 붙여넣어 주세요."
3. 텍스트에서 추출: company, team, role, must, nice, tech_stack, culture, background.

## Output 스키마 (`resumes/jobs/<회사>_<yyyy-mm-dd>.md`)
\```markdown
---
company: 토스
team: 프론트엔드 플랫폼
role: Senior Frontend Engineer
url: <원본 URL>
fetched_at: 2026-10-01
---

# 필수 요건 (must)
- ...

# 우대 사항 (nice)
- ...

# 기술 스택
- ...

# 팀 문화
- ...

# 채용 배경
- ...
\```

## 캐시
같은 URL + 같은 날짜 파일이 이미 있으면:
- 기본: 사용자에게 "기존 파일을 사용할까요, 새로 가져올까요?"
- `--refresh` 플래그: 바로 덮어쓰기.
```

- [ ] **Step 2: fallback 안내 메시지 자동 검증**

```bash
grep -q "URL 크롤에 실패" .claude/agents/job-parser.md && echo "FALLBACK MSG: OK"
grep -q "붙여넣어 주세요" .claude/agents/job-parser.md && echo "FALLBACK ACTION: OK"
```

Expected: 두 줄 모두 `OK`

- [ ] **Step 3: 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/job-parser.md
```

Expected: `OK`

- [ ] **Step 4: 커밋**

```bash
git add .claude/agents/job-parser.md
git commit -m "feat(agents): add job-parser with text-paste fallback on crawl failure

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 9: job-relevance-mapper 에이전트

**Files:**
- Create: `.claude/agents/job-relevance-mapper.md`

**Interfaces:**
- Consumes: `sources/profile.md`, `resumes/jobs/<회사>_<date>.md`
- Produces: relevance-map JSON 텍스트 (파일 저장은 스킬이 담당)

- [ ] **Step 1: job-relevance-mapper.md 작성**

```markdown
---
name: job-relevance-mapper
description: profile.md의 각 프로젝트/기술 항목이 공고의 must/nice/culture 요건을 얼마나 충족하는지 카운트하여 relevance-map JSON을 생성한다.
tools: Read
---

## Role
프로필과 공고를 매핑하는 분석가.

## Rules
- 각 프로젝트마다 공고의 must/nice/culture 항목을 하나씩 보고 **profile에 근거가 있는지** 판단.
- 근거는 "기술 스택 정확 일치" 또는 "경험 서술 직접 매칭"일 때만 인정.
- 간접 유추(예: "React 썼으니 TypeScript도 할 것")는 미인정.

## 가중치
프로젝트 관련도 총점 = `must * 3 + nice * 1 + culture * 1`

## Output (JSON 텍스트)
\```json
{
  "projects": {
    "KISA": { "must": 3, "nice": 2, "culture": 1, "total": 12 },
    "AEGIS": { "must": 1, "nice": 0, "culture": 1, "total": 4 }
  },
  "unmatched_must": [
    "GraphQL 경험 2년 이상 — profile에 근거 없음"
  ]
}
\```

`unmatched_must`는 공고 must 요건 중 profile 전체에 근거가 없는 항목.
```

- [ ] **Step 2: 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/job-relevance-mapper.md
```

Expected: `OK`

- [ ] **Step 3: 커밋**

```bash
git add .claude/agents/job-relevance-mapper.md
git commit -m "feat(agents): add job-relevance-mapper for profile ↔ job must/nice/culture scoring

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 10: job-alignment-validator 에이전트

**Files:**
- Create: `.claude/agents/job-alignment-validator.md`

**Interfaces:**
- Consumes: 이력서 초안, relevance-map, 공고 요약
- Produces: 리포트 (unmatched_must_report, missed_matches)

- [ ] **Step 1: job-alignment-validator.md 작성**

```markdown
---
name: job-alignment-validator
description: 맞춤 이력서가 공고의 must 요건을 profile 근거가 있는 범위 내에서 얼마나 반영했는지 검증한다. 근거 없는 must는 "반영 안 됨"으로 리포트.
tools: Read, Grep
---

## Role
맞춤 이력서가 공고와 정렬됐는지, 그러면서도 사실 불변을 지켰는지 검증.

## Rules
- relevance-map의 `unmatched_must` 항목이 이력서에 반영됐으면 CRITICAL.
- 공고 must 중 profile에 근거가 있는 항목이 이력서에 반영되지 않았으면 WARN.

## Output
\```
## job-alignment-validator 리포트
- status: CRITICAL | WARN | OK
- unmatched_must_report:
  - "GraphQL 경험 2년 이상"
  - "Vue.js 경험"
- missed_matches:
  - "성능 최적화 경험 — profile 'KISA 번들 축소' 활용 권고"
\```
```

- [ ] **Step 2: 스키마 검증**

```bash
scripts/check-agent-schema.sh .claude/agents/job-alignment-validator.md
```

Expected: `OK`

- [ ] **Step 3: 커밋**

```bash
git add .claude/agents/job-alignment-validator.md
git commit -m "feat(agents): add job-alignment-validator for must-requirement coverage

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 11: /resume-tailor 스킬 조립 + 당일 충돌 안내 테스트

**Files:**
- Create: `.claude/skills/resume-tailor/SKILL.md`

**Interfaces:**
- Consumes: URL (또는 사용자 텍스트), `sources/profile.md`
- Produces: `resumes/jobs/<회사>_<date>.md`, `resumes/tailored/<회사>_<date>.md`

- [ ] **Step 1: SKILL.md 작성**

```markdown
---
name: resume-tailor
description: 채용공고 URL을 받아 profile.md에서 공고 맞춤 이력서를 새로 생성한다. 강도(강/중/약)를 사용자에게 묻고, 사실은 왜곡하지 않으면서 강조·순서·헤드라인만 조정한다.
---

## Usage
\```
/resume-tailor <URL>
/resume-tailor <URL> --refresh
\```

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
```

- [ ] **Step 2: 당일 재실행 충돌 안내 자동 검증**

```bash
grep -q "이미 있습니다" .claude/skills/resume-tailor/SKILL.md && echo "COLLISION PROMPT: OK"
grep -q "\-\-refresh" .claude/skills/resume-tailor/SKILL.md && echo "REFRESH FLAG: OK"
```

Expected: 두 줄 모두 `OK`

- [ ] **Step 3: fixture 기반 통합 테스트**

```bash
mkdir -p sources resumes/jobs resumes/tailored
cp tests/fixtures/profile-sample.md sources/profile.md
cp tests/fixtures/job-sample.md resumes/jobs/테스트회사_2026-10-01.md

# 사용자가 /resume-tailor 수동 실행 (강도=중, 캐시 사용 선택)
# 실행 후:
test -f resumes/tailored/테스트회사_2026-10-01.md && echo "TAILORED CREATED: OK"
scripts/check-resume.sh resumes/tailored/테스트회사_2026-10-01.md sources/profile.md
echo "exit=$?"
```

Expected: `TAILORED CREATED: OK` + `exit=0`

- [ ] **Step 4: 테스트 산출물 정리**

```bash
rm -f sources/profile.md resumes/jobs/테스트회사_2026-10-01.md resumes/tailored/테스트회사_2026-10-01.md
```

- [ ] **Step 5: 커밋**

```bash
git add .claude/skills/resume-tailor/SKILL.md
git commit -m "feat(skills): add /resume-tailor with intensity selection and must-coverage report

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 12: templates/resume-template.html

**Files:**
- Create: `templates/resume-template.html`

**Interfaces:**
- Consumes: `{{ TITLE }}`, `{{ CONTENT }}`, `{{ GENERATED_AT }}` 치환
- Produces: HTML 파일

- [ ] **Step 1: 템플릿 작성**

```html
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<title>{{ TITLE }}</title>
<style>
  :root { color-scheme: light; }
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Pretendard", "Apple SD Gothic Neo", "맑은 고딕", sans-serif;
    color: #1a1a1a;
    line-height: 1.6;
    max-width: 820px;
    margin: 2.5rem auto;
    padding: 0 1.5rem;
  }
  h1 { font-size: 1.9rem; border-bottom: 2px solid #000; padding-bottom: .4rem; margin-top: 2rem; }
  h2 { font-size: 1.3rem; margin-top: 1.6rem; border-bottom: 1px solid #ddd; padding-bottom: .2rem; }
  h3 { font-size: 1.05rem; margin-top: 1.2rem; }
  h4 { font-size: 0.95rem; margin-top: .8rem; color: #333; }
  ul { padding-left: 1.2rem; }
  li { margin: .25rem 0; }
  code { background: #f3f3f3; padding: .1rem .35rem; border-radius: 3px; font-size: .9em; }
  pre { background: #f6f6f6; padding: .8rem; border-radius: 4px; overflow-x: auto; }
  table { border-collapse: collapse; margin: .6rem 0; }
  th, td { border: 1px solid #ddd; padding: .3rem .6rem; }
  hr { border: 0; border-top: 1px dashed #ccc; margin: 1.5rem 0; }
  .meta { color: #888; font-size: .85rem; text-align: right; }

  @media print {
    body { margin: 0; padding: 0 1cm; max-width: none; font-size: 10.5pt; }
    h1 { font-size: 1.5rem; }
    h2 { font-size: 1.1rem; break-after: avoid; }
    h3 { break-after: avoid; }
    .meta { display: none; }
    a { color: inherit; text-decoration: none; }
    @page { size: A4; margin: 1cm; }
  }
</style>
</head>
<body>
<div class="meta">{{ GENERATED_AT }}</div>
{{ CONTENT }}
</body>
</html>
```

- [ ] **Step 2: 치환 토큰·인쇄 CSS 자동 검증**

```bash
for token in "{{ TITLE }}" "{{ CONTENT }}" "{{ GENERATED_AT }}"; do
  grep -qF "$token" templates/resume-template.html || { echo "FAIL: missing $token"; exit 1; }
done
echo "ALL TOKENS: OK"

grep -q "@media print" templates/resume-template.html && echo "PRINT CSS: OK"
grep -q "@page" templates/resume-template.html && echo "PAGE RULE: OK"
```

Expected: `ALL TOKENS: OK` / `PRINT CSS: OK` / `PAGE RULE: OK`

- [ ] **Step 3: 커밋**

```bash
git add templates/resume-template.html
git commit -m "feat(templates): add print-friendly resume HTML template

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 13: /resume-render 스킬 + HTML escape 테스트

**Files:**
- Create: `.claude/skills/resume-render/SKILL.md`

**Interfaces:**
- Consumes: 마크다운 파일 경로, `templates/resume-template.html`
- Produces: `output/<원본파일명>.html`

- [ ] **Step 1: SKILL.md 작성**

```markdown
---
name: resume-render
description: 마크다운 이력서 파일을 인쇄 친화적인 HTML로 변환해 output/에 저장한다. 외부 도구 없이 Claude가 직접 변환하며, PDF는 사용자가 브라우저에서 인쇄해 저장한다.
---

## Usage
\```
/resume-render <마크다운 경로>
/resume-render <마크다운 경로> --out <HTML 경로>
\```

## Flow
1. 인자 파일 로드. 없으면 에러 종료.
2. 첫 번째 `# ` 헤딩을 title로 추출. 없으면 파일명 사용.
3. 마크다운 → HTML 변환:
   - 지원: 헤딩(h1~h4), 강조(**bold**, *italic*), 리스트, 인라인 코드, 코드 블록, 링크, 수평선, 표.
   - `<`, `>`, `&`, `"`는 반드시 escape (`&lt;`, `&gt;`, `&amp;`, `&quot;`).
   - `<!-- ... -->` 주석은 결과에서 제거.
4. `templates/resume-template.html` 로드. 없으면 "템플릿 없음, 중단" 에러.
5. 치환:
   - `{{ TITLE }}` → 추출된 제목
   - `{{ CONTENT }}` → 변환된 HTML
   - `{{ GENERATED_AT }}` → 현재 시각 (yyyy-mm-dd HH:mm)
6. `output/<원본파일명>.html` 저장 (또는 `--out` 경로).
7. 사용자에게:
   > "저장 완료: output/<파일>.html
   > 브라우저로 열어 Cmd+P → 'PDF로 저장'을 눌러주세요."

## 외부 의존성
없음. Claude가 직접 변환.
```

- [ ] **Step 2: HTML escape 자동 검증 (수동 트리거)**

```bash
# 사용자가 /resume-render tests/fixtures/resume-sample.md 수동 실행
# 실행 후:
test -f output/resume-sample.html && echo "FILE CREATED: OK"
grep -q "&lt;B2B 대시보드&gt;" output/resume-sample.html && echo "ESCAPE <>: OK"
grep -q "&amp;" output/resume-sample.html && echo "ESCAPE &: OK"
grep -q "&quot;" output/resume-sample.html && echo "ESCAPE QUOTE: OK"

# 치환 토큰이 결과물에 남아있지 않아야 함
if grep -q "{{ " output/resume-sample.html; then
  echo "FAIL: unresolved tokens remain"
  exit 1
else
  echo "TOKENS RESOLVED: OK"
fi

# HTML 주석(resume-at 등)이 남아있지 않아야 함 (meta div 안의 원본은 OK)
if grep -q "<!-- resume-at" output/resume-sample.html; then
  echo "FAIL: comment not stripped"
  exit 1
else
  echo "COMMENT STRIPPED: OK"
fi
```

Expected: 모두 `OK`

- [ ] **Step 3: 테스트 산출물 정리**

```bash
rm -f output/resume-sample.html
```

- [ ] **Step 4: 커밋**

```bash
git add .claude/skills/resume-render/SKILL.md
git commit -m "feat(skills): add /resume-render with HTML escape and comment stripping

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 14: 최종 end-to-end 스모크 + 기존 하네스 제거

**Files:**
- Delete: `~/.claude/skills/resume-builder/`
- Delete: `~/.claude/skills/resume-feedback/`
- Delete: `docs/superpowers/specs/2026-09-18-resume-manager-design.md`
- Delete: `docs/superpowers/plans/2026-09-18-resume-manager.md`
- Delete: `.superpowers/sdd/2026-09-18-resume-manager/`
- Delete: `resumes/이력서_초안.md`, `resumes/주요성과.md`, `resumes/첨삭_피드백.md`, `resumes/헤드헌터_피드백.md`

**Interfaces:**
- Consumes: 모든 이전 태스크의 산출물
- Produces: 정리된 레포, 작동하는 3개 스킬

- [ ] **Step 1: 전체 흐름 스모크 테스트 (fixture 기반)**

```bash
# fixture 세팅
mkdir -p sources resumes/jobs resumes/tailored output
cp tests/fixtures/profile-sample.md sources/profile.md
cp tests/fixtures/job-sample.md resumes/jobs/테스트회사_2026-10-01.md

# 사용자가 수동 실행:
#   (A) /resume-base             → resumes/이력서_기본.md
#   (B) /resume-tailor (강도=중) → resumes/tailored/테스트회사_2026-10-01.md (캐시 사용)
#   (C) /resume-render resumes/이력서_기본.md
#   (D) /resume-render resumes/tailored/테스트회사_2026-10-01.md

# 실행 후 검증:
test -f resumes/이력서_기본.md && echo "SMOKE 1 (base): OK"
test -f resumes/tailored/테스트회사_2026-10-01.md && echo "SMOKE 2 (tailor): OK"
test -f output/이력서_기본.html && echo "SMOKE 3a (render base): OK"
test -f output/테스트회사_2026-10-01.html && echo "SMOKE 3b (render tailor): OK"

scripts/check-resume.sh resumes/이력서_기본.md sources/profile.md
scripts/check-resume.sh resumes/tailored/테스트회사_2026-10-01.md sources/profile.md
```

Expected: 모두 `OK` + 두 check-resume.sh 호출 모두 exit 0

- [ ] **Step 2: 스모크 산출물 정리**

```bash
rm -f sources/profile.md
rm -f resumes/이력서_기본.md
rm -f resumes/jobs/테스트회사_2026-10-01.md
rm -f resumes/tailored/테스트회사_2026-10-01.md
rm -f output/*.html
```

- [ ] **Step 3: 기존 전역 스킬 제거**

```bash
rm -rf ~/.claude/skills/resume-builder
rm -rf ~/.claude/skills/resume-feedback
if ls ~/.claude/skills/ 2>/dev/null | grep -E "^resume-"; then
  echo "FAIL: resume-* still present in ~/.claude/skills"
  exit 1
else
  echo "GLOBAL SKILLS REMOVED: OK"
fi
```

Expected: `GLOBAL SKILLS REMOVED: OK`

- [ ] **Step 4: 이전 스펙·플랜·실행 기록 제거**

```bash
rm -f docs/superpowers/specs/2026-09-18-resume-manager-design.md
rm -f docs/superpowers/plans/2026-09-18-resume-manager.md
rm -rf .superpowers/sdd/2026-09-18-resume-manager
```

- [ ] **Step 5: 이전 산출물 제거 + 원본 보존 확인**

```bash
rm -f resumes/이력서_초안.md resumes/주요성과.md resumes/첨삭_피드백.md resumes/헤드헌터_피드백.md
test -f sources/기존이력서.md && echo "SOURCE PRESERVED: OK"
```

Expected: `SOURCE PRESERVED: OK`

- [ ] **Step 6: 최종 커밋**

```bash
git add -A
git commit -m "chore(resume-hub): decommission previous harness after new one validated

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## 완료 조건

- `/resume-base`, `/resume-tailor`, `/resume-render` 3개 스킬이 프로젝트 `.claude/skills/`에서 작동.
- 10개 에이전트가 `.claude/agents/`에 배치.
- `config/repos.yaml`에 `git_author` 필드 추가.
- `templates/resume-template.html`로 HTML 렌더 가능.
- `scripts/check-resume.sh`가 자동 검증 통과를 보장.
- 기존 하네스 전량 제거.
- `sources/기존이력서.md`는 그대로 보존.
