---
name: resume-build
description: 로컬 Git 레포지토리를 분석해 이력서를 자동 생성하는 전체 파이프라인. /resume-build로 실행.
---

# Resume Build Skill

Git 커밋 분석 → 이력서 작성 → 전문가 피드백 → 최종 확정 → HTML 출력의 전체 파이프라인.

## 사전 조건 확인

아래 파일 존재 여부를 확인한다. 없으면 안내 후 중단.

- `config/repos.yaml` 없으면: "`config/repos.example.yaml`을 복사해 `config/repos.yaml`을 작성해주세요."
- `config/profile.yaml` 없으면: "`config/profile.example.yaml`을 복사해 `config/profile.yaml`에 개인정보를 입력해주세요."

## Phase 1: 커밋 분석

`commit-analyzer` 에이전트를 실행한다.

에이전트가 `resumes/주요성과.md` 작성 완료 후 사용자 검토를 요청한다. 사용자가 '계속' 또는 수정 사항을 입력하면 다음 단계로 진행한다.

## Phase 2: 이력서 초안 작성

`resume-writer` 에이전트를 실행한다. `resumes/이력서_초안.md` 작성 완료 후 즉시 Phase 3으로 진행한다 (사용자 대기 없음).

## Phase 3: 전문가 피드백 (병렬)

`resume-critic`과 `headhunter` 에이전트를 **반드시 동시에** 실행한다.
두 에이전트 실행 시 `resumes/이력서_초안.md`를 대상 파일로 지정한다.

- `resume-critic` → `resumes/첨삭_피드백.md`
- `headhunter` → `resumes/헤드헌터_피드백.md`

두 에이전트 완료 후 사용자에게 안내:
"`resumes/첨삭_피드백.md`와 `resumes/헤드헌터_피드백.md`를 확인해주세요.
반영할 피드백을 알려주시면 이력서를 수정하겠습니다.
피드백 없이 진행하려면 '건너뛰기'를 입력해주세요."

사용자 지시에 따라 `resumes/이력서_초안.md`를 수정한 뒤 `resumes/이력서_최종.md`로 저장한다.

## Phase 4: 최종 확인

"최종 이력서(`resumes/이력서_최종.md`)를 확인해주세요.
수정이 없으면 '확정'을 입력해주세요."

사용자 확정 후 Phase 5로 진행.

## Phase 5: HTML 생성

`templates/resume-template.html`을 읽어 `resumes/이력서_최종.md` 내용으로 플레이스홀더를 채운 HTML 파일을 생성한다.

**사전 준비:**

```bash
mkdir -p output
```

**플레이스홀더 치환 규칙:**

| 플레이스홀더 | 소스 |
|-------------|------|
| `{{NAME}}` | config/profile.yaml의 name |
| `{{TITLE}}` | config/profile.yaml의 title |
| `{{PHONE}}` | config/profile.yaml의 contact.phone |
| `{{EMAIL}}` | config/profile.yaml의 contact.email |
| `{{GITHUB}}` | config/profile.yaml의 contact.github |
| `{{SUMMARY}}` | 이력서 요약 섹션 → `<p>` 태그 |
| `{{EXPERIENCE_BLOCKS}}` | 경력 섹션 → `company-block` > `project-block` 구조 |
| `{{PROJECT_BLOCKS}}` | 개인 프로젝트 → `project-block` 구조 |
| `{{SKILLS_BLOCK}}` | 기술 스택 → `<p class="skills-row">` 태그 |

**Markdown → HTML 변환 규칙:**
- `- ` 목록 → `<ul><li>` 변환
- `**텍스트**` → `<strong>텍스트</strong>`
- `> 텍스트` (인용구) → `<div class="project-desc">텍스트</div>`

**경력 섹션 HTML 구조 예시:**

```html
<div class="company-block">
  <div class="company-header">
    <span class="company-name">회사명</span>
    <span class="period">2022.03~2025.09</span>
  </div>
  <div class="role">프론트엔드 개발자</div>
  <div class="project-block">
    <div class="project-name">프로젝트명 <span class="project-desc">한 줄 설명 | Tech Stack</span></div>
    <ul>
      <li>PAR 성과 항목</li>
    </ul>
  </div>
</div>
```

**기술 스택 HTML 구조 예시:**

```html
<p class="skills-row"><strong>Frontend:</strong> React, TypeScript, Next.js</p>
<p class="skills-row"><strong>State/Data:</strong> Zustand, React Query</p>
```

출력: `output/이력서_{오늘날짜_YYYY-MM-DD}.html`

완료 후: "`output/이력서_{날짜}.html` 생성 완료. 브라우저에서 열어 확인 후 'PDF로 다운로드' 버튼으로 저장하세요."

## 주의사항

- Phase 1, 3에서 사용자 승인 없이 다음 단계로 진행하지 않는다
- Phase 3의 두 에이전트는 반드시 병렬(동시) 실행한다
- HTML 생성 시 `templates/resume-template.html`의 CSS는 수정하지 않는다
- `resumes/` 디렉토리가 없으면 `mkdir -p resumes` 실행 후 진행
