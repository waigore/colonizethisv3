# Workspace outdated audit (manual command set)

**SPEC/program** — Manual driver to enumerate `pub outdated` for the workspace host root and every workspace member, used to validate dependency-refresh progress for **#2073**. Sub-spec of [pub-workspace-toolchain.md](pub-workspace-toolchain.md). Not gameplay or simulation behavior.

---

## Audit command set

Run this sequence from a clean checkout on the pinned Flutter/Dart toolchain:

```bash
dart pub outdated
python3 - <<'PY' | while IFS=$'\t' read -r tool pkg; do
import pathlib
root = pathlib.Path('.')
lines = (root / 'pubspec.yaml').read_text().splitlines()
members = []
in_workspace = False
for line in lines:
    stripped = line.strip()
    if not in_workspace:
        if stripped == 'workspace:':
            in_workspace = True
        continue
    if stripped.endswith(':') and not line.startswith(' '):
        break
    if stripped.startswith('- '):
        members.append(stripped[2:].strip())
for member in members:
    pubspec = root / member / 'pubspec.yaml'
    if not pubspec.exists():
        continue
    tool = 'flutter' if 'sdk: flutter' in pubspec.read_text() else 'dart'
    print(f"{tool}\t{member}")
PY
  (cd "$pkg" && "$tool" pub outdated)
done
```

## Interpretation

- If a package is below **Resolvable**, treat it as actionable implementation work (constraints / lockfile lagging).
- If a package is at **Resolvable** but below **Latest**, verify it is covered by an entry in [pub-workspace-toolchain.md § Intentional dependency caps](pub-workspace-toolchain.md#intentional-dependency-caps) before considering #2073 complete.
- Record the audit result in the linked issue / PR so reviewers can distinguish solved from deferred dependency gaps.

## CI-facing equivalents

- `dart run tool/ct_repo_lint.dart --rule repo.workspace_outdated_resolvable` — fails when any audited row has `current != resolvable`.
- `dart run tool/ct_repo_lint.dart --rule repo.workspace_outdated_latest_direct` — fails when a direct / dev row is below `Latest` while `Latest == Resolvable`.

## Temporary exclusion override

Both rules read `CT_WORKSPACE_OUTDATED_EXCLUDE` (comma-separated package list, e.g. `custom_lint_builder,analyzer_plugin`). Keep the list minimal and document the exact blocker in the linked issue / PR.

## Acceptance criteria

- Given a clean checkout on the pinned Flutter/Dart toolchain, when a maintainer runs the documented audit command set from the repository root, then the combined output contains a `pub outdated` table for the workspace host root plus one table per workspace member that has a `pubspec.yaml`.
- Given an audit result row reported below **Resolvable**, when no intentional cap applies, then the maintainer treats the row as actionable for #2073 (constraint update, coordinated bump, or lockfile refresh).
- Given an audit result row at **Resolvable** but below **Latest**, when the row matches an entry in [pub-workspace-toolchain.md § Intentional dependency caps](pub-workspace-toolchain.md#intentional-dependency-caps), then the row is treated as a documented exception and not as #2073 work.
- Given `CT_WORKSPACE_OUTDATED_EXCLUDE` is set when running the CI rules, when the rules execute, then they exclude listed package names from violation checks and the using PR / issue documents why the exception is temporary.
