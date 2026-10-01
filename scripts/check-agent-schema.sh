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
