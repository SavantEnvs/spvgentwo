#!/usr/bin/env bash
#
# mayhem/test.sh — RUN the upstream Catch2 test suite (built by mayhem/build.sh into
# build-tests/, discovered by ctest). Asserts real behavior (Catch2 REQUIRE assertions +
# spirv-val module validation); emits a CTRF summary.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

RUNNER="$SRC/build-tests/SpvGenTwoTests"
if [ ! -x "$RUNNER" ]; then
  echo "test.sh: $RUNNER missing — mayhem/build.sh must build the test suite" >&2
  emit_ctrf "catch2" 0 1
  exit 1
fi

# Run the Catch2 suite directly and parse its own assertion summary (behavioral:
# a neutered/exit(0) binary produces no summary and fails the parse below).
LOG=/tmp/catch2.log
"$RUNNER" > "$LOG" 2>&1
rc=$?
tail -5 "$LOG"

# Catch2 v3 summaries:
#   "All tests passed (96 assertions in 18 test cases)"
#   "test cases: 18 | 17 passed | 1 failed"
passed=""; failed=""
if grep -qE 'All tests passed \([0-9]+ assertions in [0-9]+ test cases?\)' "$LOG"; then
  passed=$(sed -nE 's/.*All tests passed \([0-9]+ assertions in ([0-9]+) test cases?\).*/\1/p' "$LOG" | tail -1)
  failed=0
else
  passed=$(sed -nE 's/.*test cases:[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*([0-9]+) passed.*/\1/p' "$LOG" | tail -1)
  failed=$(sed -nE 's/.*test cases:.*\|[[:space:]]*([0-9]+) failed.*/\1/p' "$LOG" | tail -1)
fi
if [ -z "$passed" ] || [ "${passed:-0}" -eq 0 ]; then
  echo "test.sh: could not parse Catch2 summary (or zero tests ran) — treating as failure" >&2
  emit_ctrf "catch2" 0 1
  exit 1
fi
failed=${failed:-0}
[ "$rc" -ne 0 ] && [ "$failed" -eq 0 ] && failed=1

emit_ctrf "catch2" "$passed" "$failed"
