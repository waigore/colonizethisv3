# Game widgets file size (repo lint)

**SPEC/program** — physical line limit for Dart sources under the in-game Flutter
widget tree. Umbrella policy: `SPEC/program/repo-lint.md` (**no violation
allowlists**).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_game_widgets_file_size.dart` | Walker, counter, CLI |
| `tool/ct_repo_lint_manifest.yaml` | Registers rule `repo.game_widgets_file_size` |

## Scan scope

- Recursive listing under
  `app/lib/features/game/widgets/` (repository-relative).
- Only files ending in `.dart` are measured.
- If that directory is missing, the checker fails the run (repository layout
  contract for the ColonizeThis app).

## Measurement contract

- **Physical lines:** `LineSplitter` line count of the file’s UTF-8 text (same
  as `const LineSplitter().convert(content).length` in the checker).
- **Threshold:** each scanned file must have **700** physical lines or fewer
  (701 or more fails).

There is **no** YAML, keyed table, or per-file exemption that raises the
effective cap for a specific path.

## Acceptance criteria

- Given a temporary workspace that contains
  `app/lib/features/game/widgets/over.dart` with **701** physical lines and no
  other violating files, when the System runs `runCheckGameWidgetsFileSize` with
  that workspace root, then the checker exits non-zero and the error output
  names `over.dart` and reports a line count strictly greater than 700.

- Given a temporary workspace whose only matching file is
  `app/lib/features/game/widgets/ok.dart` with exactly **700** physical lines,
  when the System runs `runCheckGameWidgetsFileSize`, then the checker exits
  zero.

- Given a temporary workspace that does not contain the directory
  `app/lib/features/game/widgets/`, when the System runs
  `runCheckGameWidgetsFileSize`, then the checker exits non-zero and reports that
  the widgets directory was not found.

- Given the repository root as cwd, when CI runs
  `dart run tool/ct_repo_lint.dart` and rule `repo.game_widgets_file_size` is in
  scope, then the rule enforces the threshold above and does not load keyed
  waiver data to waive failures for in-scope Dart files.

- Given a temporary workspace that contains
  `app/lib/features/game/widgets/huge.dart` with **701** physical lines and a
  decoy file `tool/legacy_game_widgets_waiver_table.yaml` shaped like historical
  keyed waiver YAML (for example listing `huge.dart` under `exempt_files`), when
  the System runs `runCheckGameWidgetsFileSize` with that workspace root, then
  the checker still exits non-zero and reports `huge.dart` as over the line
  limit, because no keyed waiver data is loaded.
