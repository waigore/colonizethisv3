# App catalog widgets file size (repo lint)

**SPEC/program** — physical line limit for hand-written Dart sources under the
shared Ct-* catalog root `app/lib/widgets/**`. Umbrella policy:
`SPEC/program/repo-lint.md` (**no violation allowlists**). Refs #4352 Slice B / AC4.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_app_catalog_widgets_file_size.dart` | Walker, counter, CLI |
| `tool/ct_repo_lint_manifest.yaml` | Registers rule `repo.app_catalog_widgets_file_size` |

## Scan scope

- Recursive listing under `app/lib/widgets/` (repository-relative).
- Only files ending in `.dart` are measured; generated suffixes
  (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`) are excluded.
- If that directory is missing, the checker fails the run (repository layout
  contract for the ColonizeThis app).

## Measurement contract

- **Physical lines:** `LineSplitter` line count of the file’s UTF-8 text (same
  as `const LineSplitter().convert(content).length` in the checker).
- **Threshold:** each scanned file must have **300** physical lines or fewer
  (301 or more fails).

There is **no** YAML, keyed table, or per-file exemption that raises the
effective cap for a specific path.

## Acceptance criteria

- Given a temporary workspace that contains
  `app/lib/widgets/over.dart` with **301** physical lines and no other violating
  files, when the System runs `runCheckAppCatalogWidgetsFileSize` with that
  workspace root, then the checker exits non-zero and the error output names
  `over.dart` and reports a line count strictly greater than 300.

- Given a temporary workspace whose only matching file is
  `app/lib/widgets/ok.dart` with exactly **300** physical lines, when the System
  runs `runCheckAppCatalogWidgetsFileSize`, then the checker exits zero.

- Given a temporary workspace that does not contain the directory
  `app/lib/widgets/`, when the System runs `runCheckAppCatalogWidgetsFileSize`,
  then the checker exits non-zero and reports that the widgets directory was not
  found.

- Given the repository root as cwd, when CI runs
  `dart run tool/ct_repo_lint.dart` and rule `repo.app_catalog_widgets_file_size`
  is in scope, then the rule enforces the threshold above.
