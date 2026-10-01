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
