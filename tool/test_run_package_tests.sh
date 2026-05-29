#!/usr/bin/env bash
# Regression tests for tool/run_package_tests.sh
#
# Issue #2957: under `set -euo pipefail`, the parent script previously exited
# on the first iteration because of `((task_idx++))` (post-increment returns 0
# when task_idx=0, which makes `((expr))` exit 1). Real shard failures were
# also silently dropped because the per-shard subshell inherited `set -e` and
# never wrote rc.* on failure.
#
# These tests stub `dart` and `lcov` with fake commands so the runner can be
# exercised offline and quickly. They drive `tool/run_package_tests.sh` end to
# end with synthetic package layouts and assert exit code + summary line.
#
# Run directly:
#   bash tool/test_run_package_tests.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/tool/run_package_tests.sh"

if [ ! -x "$SCRIPT" ] && [ ! -f "$SCRIPT" ]; then
  echo "FAIL: cannot find $SCRIPT" >&2
  exit 1
fi

PASS_COUNT=0
FAIL_COUNT=0
FAIL_NAMES=()

# --- helpers ---------------------------------------------------------------

# build_fake_workspace <root> <pkg-spec...>
#   Each pkg-spec is "name:dart_exit_code". Creates <root>/packages/<name>/test/x_test.dart
#   plus pubspec.yaml, builds a fake `dart` shim under <root>/bin that records
#   invocations and returns the requested exit code per package.
build_fake_workspace() {
  local target="$1"; shift
  mkdir -p "$target/bin"
  : > "$target/bin/_dart_calls.log"

  local cases_block=""
  for spec in "$@"; do
    local name="${spec%%:*}"
    local rc="${spec##*:}"
    mkdir -p "$target/packages/$name/test"
    cat > "$target/packages/$name/pubspec.yaml" <<EOF
name: $name
environment:
  sdk: '>=3.0.0 <4.0.0'
EOF
    cat > "$target/packages/$name/test/x_test.dart" <<EOF
// fake test for $name
void main() {}
EOF
    cases_block="${cases_block}      */packages/${name}*) exit ${rc} ;;
"
  done

  cat > "$target/bin/dart" <<EOF
#!/usr/bin/env bash
# Fake \`dart\` for tool/run_package_tests.sh tests.
# - For \`dart test ...\`: print a fake "All tests passed!" or failure line and
#   exit with the rc encoded in the package path (matched by case below).
# - For \`dart run coverage:format_coverage ...\`: just create the requested
#   output file so coverage merge can proceed.
# - For \`dart pub get\`: succeed silently.
echo "fake-dart \$*" >> "$target/bin/_dart_calls.log"
case "\$1" in
  test)
    pwd="\$(pwd)"
    case "\$pwd" in
${cases_block}      *) echo "fake-dart: unexpected pwd \$pwd" >&2; exit 99 ;;
    esac
    ;;
  run)
    # dart run coverage:format_coverage --lcov -i <in> -o <out> --report-on=lib --package=.
    out=""
    while [ \$# -gt 0 ]; do
      case "\$1" in
        -o) out="\$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    if [ -n "\$out" ]; then
      mkdir -p "\$(dirname "\$out")"
      printf 'TN:\nSF:lib/foo.dart\nDA:1,1\nLF:1\nLH:1\nend_of_record\n' > "\$out"
    fi
    exit 0
    ;;
  pub)
    exit 0
    ;;
esac
exit 0
EOF
  chmod +x "$target/bin/dart"

  # Fake lcov: just concatenate -a inputs to -o output. Real lcov isn't needed.
  cat > "$target/bin/lcov" <<'EOF'
#!/usr/bin/env bash
out=""
inputs=()
while [ $# -gt 0 ]; do
  case "$1" in
    -a) inputs+=("$2"); shift 2 ;;
    -o) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
if [ -n "$out" ]; then
  mkdir -p "$(dirname "$out")"
  : > "$out"
  for f in "${inputs[@]}"; do
    [ -f "$f" ] && cat "$f" >> "$out"
  done
fi
exit 0
EOF
  chmod +x "$target/bin/lcov"
}

run_case() {
  local name="$1"; shift
  local expected_rc="$1"; shift
  local pkgs_csv="$1"; shift
  local fake_root="$1"; shift
  local expected_substr="${1:-}"

  echo "--- $name ---"
  # Fake workspace exposes its own copy of run_package_tests.sh that points
  # ROOT at the fake workspace so it acts on the synthetic packages layout.
  local fake_script="$fake_root/tool/run_package_tests.sh"
  mkdir -p "$fake_root/tool"
  cp "$SCRIPT" "$fake_script"
  # Stub coverage gate so the script reaches its own exit logic without
  # depending on the real check_coverage_threshold.sh / lcov totals.
  cat > "$fake_root/tool/check_coverage_threshold.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$fake_root/tool/check_coverage_threshold.sh"

  local out_file
  out_file="$(mktemp)"
  set +e
  PATH="$fake_root/bin:$PATH" \
    PACKAGES_TO_TEST="$pkgs_csv" \
    PACKAGE_TEST_MAX_JOBS=2 \
    bash "$fake_script" >"$out_file" 2>&1
  local actual_rc=$?
  set -e

  local ok=1
  if [ "$actual_rc" -ne "$expected_rc" ]; then
    echo "  expected exit $expected_rc, got $actual_rc"
    ok=0
  fi
  if [ -n "$expected_substr" ] && ! grep -qF "$expected_substr" "$out_file"; then
    echo "  expected output to contain: $expected_substr"
    ok=0
  fi

  if [ "$ok" -eq 1 ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  PASS"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_NAMES+=("$name")
    echo "  --- output ---"
    sed 's/^/    /' "$out_file"
    echo "  --------------"
  fi
  rm -f "$out_file"
}

# --- AC1: positive — all shards pass, script exits 0 ----------------------

ac1_root="$(mktemp -d)"
trap 'rm -rf "$ac1_root"' EXIT
build_fake_workspace "$ac1_root" \
  colonizethis_models:0 \
  colonizethis_data:0 \
  colonizethis_save:0 \
  colonizethis_map:0 \
  colonizethis_logic:0 \
  colonizethis_ai:0
run_case "AC1 all shards pass" 0 \
  "colonizethis_models,colonizethis_data,colonizethis_save,colonizethis_map,colonizethis_logic,colonizethis_ai" \
  "$ac1_root" \
  "All package tests passed"

# --- AC3 (regression): single-package run — the original bug repro --------
# With the buggy ((task_idx++)), the script exited rc=1 on the first iteration
# even though the only shard succeeded. This case must now exit 0.
ac3_root="$(mktemp -d)"
build_fake_workspace "$ac3_root" colonizethis_models:0
run_case "AC3 regression first-iteration exit (single shard)" 0 \
  "colonizethis_models" \
  "$ac3_root" \
  "All package tests passed"
rm -rf "$ac3_root"

# --- AC2: negative — one shard fails, script exits non-zero ---------------
# Pre-fix this also reported success because the failing subshell never wrote
# rc.* (set -e exited the subshell before the echo line).
ac2_root="$(mktemp -d)"
build_fake_workspace "$ac2_root" \
  colonizethis_models:0 \
  colonizethis_data:7 \
  colonizethis_save:0 \
  colonizethis_map:0 \
  colonizethis_logic:0 \
  colonizethis_ai:0
run_case "AC2 one shard fails (exit 7)" 1 \
  "colonizethis_models,colonizethis_data,colonizethis_save,colonizethis_map,colonizethis_logic,colonizethis_ai" \
  "$ac2_root" \
  "FAILED: one or more package test shards failed"
rm -rf "$ac2_root"

# --- summary --------------------------------------------------------------
echo ""
echo "=========================================="
echo " run_package_tests regression: $PASS_COUNT pass, $FAIL_COUNT fail"
echo "=========================================="
if [ "$FAIL_COUNT" -gt 0 ]; then
  for n in "${FAIL_NAMES[@]}"; do
    echo "  FAIL: $n"
  done
  exit 1
fi
exit 0
