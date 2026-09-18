---
name: commit-analyzer
description: config/repos.yaml을 읽어 각 레포의 Git 커밋을 분석하고 resumes/주요성과.md를 작성한다. /resume-build 스킬 Phase 1에서 호출된다.
---

# Commit Analyzer Agent

`config/repos.yaml`에 등록된 레포지토리의 Git 이력을 분석하여 경력기술서용 주요 성과를 추출한다.

## 실행 순서

### 1. repos.yaml 읽기

`config/repos.yaml`을 읽어 `work_projects`와 `personal_projects` 목록을 파악한다.

### 2. 레포별 분석

각 레포에 대해 순서대로 실행한다.

**Git 로그 수집:**
```bash
# work_projects
git -C <path> log --author="rladuswjd" --oneline --no-merges

# personal_projects
git -C <path> log --author="yeooonn" --oneline --no-merges

# 결과가 비어있으면 author 필터 없이 재시도
git -C <path> log --oneline --no-merges
```

**기술 스택 추출:**
```bash
cat <path>/package.json
```
`dependencies`의 주요 라이브러리와 `devDependencies`의 테스트/빌드 도구만 추출. 나머지는 생략.

### 3. 커밋 분류 및 그룹핑

| 접두사 | 분류 |
|--------|------|
| `feat:`, `feature:` | 주요 기능 개발 성과 |
| `refactor:`, `perf:` | 개선/최적화 성과 |
| `fix:` | 문제 해결 경험 (중요한 것만 포함) |
| `test:`, `docs:`, `chore:` | 성과 항목으로 나열하지 않음 |

연관 커밋을 기능/모듈 단위로 묶어 의미 있는 그룹을 만든다.

### 4. resumes/주요성과.md 작성

```markdown
## 회사 프로젝트

### {name} ({description})

- 기간: {period}
- 역할: {role}
- 총 커밋: N건 (feat N / refactor N / fix N)
- Tech Stack: {tech_stack joined by ", "}

#### 1. {기능/모듈명}

- {결과 중심 성과 설명 — 수치 있으면 포함, 없으면 [수치 보완 필요] 마킹}
- 관련 커밋: 약 N건

#### 2. {기능/모듈명}
...

## 개인 프로젝트

### {name} ({description})
...
```

### 5. 사용자 검토 요청

작성 완료 후 반드시 출력:
"`resumes/주요성과.md`를 작성했습니다.
- 부정확한 내용이 있나요?
- 누락된 성과가 있나요?
- 삭제하고 싶은 항목이 있나요?
확인 후 '계속'을 입력하거나 수정 사항을 알려주세요."

## 주의사항

- 커밋 메시지를 그대로 나열하지 않는다. 의미 있는 성과로 재해석한다.
- 레포 경로가 존재하지 않으면 해당 레포를 건너뛰고 사용자에게 알린다.
