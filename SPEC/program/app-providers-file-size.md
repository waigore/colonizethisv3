# App providers file size (repo lint)

**SPEC/program** — physical line limit for hand-written Dart sources under
`app/lib/providers/**`. Umbrella policy: `SPEC/program/repo-lint.md`
(**no violation allowlists**). Refs #4720 Slice D / AC10–AC11.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_app_providers_file_size.dart` | Walker, counter, CLI |
| `tool/ct_repo_lint_manifest.yaml` | Registers rule `repo.app_providers_file_size` |

## Scan scope

- Recursive listing under `app/lib/providers/` (repository-relative).
- Only files ending in `.dart` are measured; generated suffixes
  (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`) are excluded.
- If that directory is missing, the checker fails the run (repository layout
  contract for the ColonizeThis app).

## Measurement contract

- **Physical lines:** `LineSplitter` line count of the file’s UTF-8 text (same
  as `const LineSplitter().convert(content).length` in the checker).
- **Threshold:** each scanned file must have **250** physical lines or fewer
  (251 or more fails). Wave-24 #4720 introduces this gate after topic-splitting
  the three oversized provider modules from wave 23.

There is **no** YAML, keyed table, or per-file exemption that raises the
effective cap for a specific path. The grandfather list stays empty.

## Acceptance criteria

- Given a temporary workspace that contains
  `app/lib/providers/too_long.dart` with **251** physical lines
  and no other violating files, when the System runs
  `runCheckAppProvidersFileSize` with that workspace root, then the checker
  exits non-zero and the error output names `too_long.dart` and reports
  `251 physical lines > 250`.

- Given a temporary workspace whose only matching file is
  `app/lib/providers/ok.dart` with exactly **250** physical
  lines, when the System runs `runCheckAppProvidersFileSize`, then the
  checker exits zero.

- Given a temporary workspace that does not contain the directory
  `app/lib/providers/`, when the System runs
  `runCheckAppProvidersFileSize`, then the checker exits non-zero and
  reports that the providers directory was not found.

- Given the repository root as cwd, when CI runs
  `dart run tool/ct_repo_lint.dart` and rule `repo.app_providers_file_size`
  is in scope, then the rule enforces the threshold above.
