---
name: resume-render
description: 마크다운 이력서 파일을 인쇄 친화적인 HTML로 변환해 output/에 저장한다. 외부 도구 없이 Claude가 직접 변환하며, PDF는 사용자가 브라우저에서 인쇄해 저장한다.
---

## Usage
```
/resume-render <마크다운 경로>
/resume-render <마크다운 경로> --out <HTML 경로>
```

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
