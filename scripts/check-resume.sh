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

# 3. 차별화 축 키워드 — 각 프로젝트(^## ) 섹션마다 두 축 모두 ≥1회 등장해야 함.
#    awk로 ^## 를 레코드 구분자처럼 사용해 섹션별 검사.
awk_result=$(awk '
  BEGIN { in_project=0; current=""; arch_ok=0; own_ok=0; failed="" }
  /^## / {
    if (in_project) {
      if (!arch_ok) failed = failed "  - 프로젝트 \"" current "\": 결정/대안/트레이드오프 키워드 없음\n"
      if (!own_ok)  failed = failed "  - 프로젝트 \"" current "\": 주도/오너십 키워드 없음\n"
    }
    in_project=1
    current=$0
    sub(/^## /, "", current)
    arch_ok=0
    own_ok=0
    next
  }
  in_project {
    if (/결정|트레이드오프|대안/) arch_ok=1
    if (/주도|오너십/) own_ok=1
  }
  END {
    if (in_project) {
      if (!arch_ok) failed = failed "  - 프로젝트 \"" current "\": 결정/대안/트레이드오프 키워드 없음\n"
      if (!own_ok)  failed = failed "  - 프로젝트 \"" current "\": 주도/오너십 키워드 없음\n"
    }
    if (!in_project) {
      # 프로젝트가 하나도 없는 이력서는 전역 체크로 폴백.
      print "NO_PROJECTS"
    } else if (failed != "") {
      printf "%s", failed
    }
  }
' "$RESUME")

if [[ "$awk_result" == "NO_PROJECTS" ]]; then
  # 프로젝트 섹션(^## )이 없는 경우: 전역 차별화 키워드 요구.
  if ! grep -qE "결정|트레이드오프|대안" "$RESUME"; then
    echo "FAIL: no 결정/트레이드오프/대안 keyword" >&2
    fail=1
  fi
  if ! grep -qE "주도|오너십" "$RESUME"; then
    echo "FAIL: no 주도/오너십 keyword" >&2
    fail=1
  fi
elif [[ -n "$awk_result" ]]; then
  echo "FAIL: per-project differentiation gaps:" >&2
  printf "%s" "$awk_result" >&2
  fail=1
fi

exit $fail
