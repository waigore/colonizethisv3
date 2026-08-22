# App feature screens file size (repo lint)

**SPEC/program** — physical line limit for Dart sources under the in-game feature
screen tree. Umbrella policy: `SPEC/program/repo-lint.md` (shrink-only grandfather
during transition slices).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_app_features_screens_lib_physical_file_size.dart` | Walker, counter, CLI |
| `tool/ct_repo_lint_manifest.yaml` | Registers rule `repo.app_features_screens_lib_physical_file_size` |

## Scan scope

- Recursive listing under `app/lib/features/game/screens/` (repository-relative).
- Only files ending in `.dart` are measured; generated suffixes
  (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`) are excluded.
- If that directory is missing, the checker fails the run (repository layout
  contract for the ColonizeThis app).

## Measurement contract

- **Physical lines:** `LineSplitter` line count of the file's UTF-8 text (same
  as `const LineSplitter().convert(content).length` in the checker).
- **Threshold:** each scanned file must have **260** physical lines or fewer
  (261 or more fails unless on the shrink-only grandfather allowlist).
  Wave-20 #4582 lowered the wave-15 **300** cap.

During wave-15 transition slices, files above the cap may appear on the
shrink-only grandfather in the checker source; stale entries (missing path or
file now at or below the cap) fail CI. The grandfather must be empty at issue
close (#4352).

## Acceptance criteria

- Given a temporary workspace that contains
  `app/lib/features/game/screens/over.dart` with **261** physical lines and no
  grandfather entry, when the System runs
  `runCheckAppFeaturesScreensLibPhysicalFileSize` with that workspace root,
  then the checker exits non-zero and the error output names `over.dart` and
  reports a line count strictly greater than 260.

- Given a temporary workspace whose only matching file is
  `app/lib/features/game/screens/ok.dart` with exactly **260** physical lines,
  when the System runs `runCheckAppFeaturesScreensLibPhysicalFileSize`, then the
  checker exits zero.

- Given a temporary workspace that does not contain the directory
  `app/lib/features/game/screens/`, when the System runs
  `runCheckAppFeaturesScreensLibPhysicalFileSize`, then the checker exits
  non-zero and reports that the screens directory was not found.

- Given the repository root as cwd, when CI runs
  `dart run tool/ct_repo_lint.dart` and rule
  `repo.app_features_screens_lib_physical_file_size` is in scope, then every
  non-grandfathered file under `app/lib/features/game/screens/**` passes the
  260 physical-line ceiling (Refs #4352, #4582).
