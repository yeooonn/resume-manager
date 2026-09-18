# resume-manager

Git 커밋 기록 기반 이력서 자동 생성 시스템 (Claude Code 기반)

## 시작하기

1. `config/repos.example.yaml`을 복사해 `config/repos.yaml` 작성
2. `config/profile.example.yaml`을 복사해 `config/profile.yaml`에 개인정보 입력
3. Claude Code에서 슬래시 커맨드 실행

> `config/repos.yaml`, `config/profile.yaml`, `resumes/`, `output/` 는 `.gitignore`에 포함되어 있습니다 (개인정보 보호).
> `resumes/tailored/`, `output/tailored/` 디렉토리는 스킬 실행 시 자동으로 생성됩니다.

## 슬래시 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/resume-build` | 전체 이력서 생성 (커밋 분석 → 작성 → 피드백 → HTML) |
| `/resume-refresh` | 기존 이력서 피드백만 재실행 |
| `/resume-tailor <URL>` | 채용 공고 맞춤 이력서 생성 |

## 출력 파일

- `resumes/이력서_최종.md` — 최종 이력서 (Markdown)
- `output/이력서_YYYY-MM-DD.html` — 브라우저에서 열어 미리보기 + PDF 다운로드
- `resumes/tailored/` — 회사별 맞춤 이력서 (Markdown)
- `output/tailored/` — 회사별 HTML (PDF 다운로드 버튼 포함)
