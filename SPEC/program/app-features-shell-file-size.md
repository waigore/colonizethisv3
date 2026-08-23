# App feature shell file size (repo lint)

**SPEC/program** — physical line limit for Dart sources under the player-app
shell tree (`settings`, new-game, save/load). Umbrella policy:
`SPEC/program/repo-lint.md` (shrink-only grandfather). Refs #4606 Slice E.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_app_features_shell_lib_physical_file_size.dart` | Walker, counter, CLI |
| `tool/ct_repo_lint_manifest.yaml` | Registers rule `repo.app_features_shell_lib_physical_file_size` |

## Scan scope

- Recursive listing under `app/lib/features/shell/` (repository-relative).
- Only files ending in `.dart` are measured; generated suffixes
  (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`) are excluded.
- If that directory is missing, the checker fails the run (repository layout
  contract for the ColonizeThis app).

## Measurement contract

- **Physical lines:** `LineSplitter` line count of the file’s UTF-8 text (same
  as `const LineSplitter().convert(content).length` in the checker).
- **Threshold:** each scanned file must have **250** physical lines or fewer
  (251 or more fails). Wave-21 #4606 adds this gate so
  `SettingsDialog` and sibling shell hosts cannot re-grow past the peer 250 cap.

The shrink-only grandfather allowlist must stay **empty**.

## Acceptance criteria

- Given a temporary workspace that contains
  `app/lib/features/shell/over.dart` with **251** physical lines and an empty
  grandfather allowlist, when the System runs
  `runCheckAppFeaturesShellLibPhysicalFileSize` with that workspace root,
  then the checker exits non-zero and the error output names `over.dart` and
  reports a line count strictly greater than 250.

- Given a temporary workspace whose only matching file is
  `app/lib/features/shell/ok.dart` with exactly **250** physical lines,
  when the System runs `runCheckAppFeaturesShellLibPhysicalFileSize`, then the
  checker exits zero.

- Given a temporary workspace that does not contain the directory
  `app/lib/features/shell/`, when the System runs
  `runCheckAppFeaturesShellLibPhysicalFileSize`, then the checker exits
  non-zero and reports that the shell directory was not found.

- Given the repository root as cwd, when CI runs
  `dart run tool/ct_repo_lint.dart` and rule
  `repo.app_features_shell_lib_physical_file_size` is in scope, then every
  non-grandfathered file under `app/lib/features/shell/**` passes the
  250 physical-line ceiling (Refs #4606).
