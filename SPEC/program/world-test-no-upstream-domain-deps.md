# World tests — no upstream domain deps (repo lint)

**SPEC/program** — repository lint gate that forbids `packages/colonizethis_world/test/**` (including `world_test_support/`) from importing `colonizethis_logic` or `colonizethis_turn`, and forbids those packages as world `pubspec.yaml` dependencies (Refs #4515). Companion to `repo.world_no_logic_deps` (lib-only) and `SPEC/program/repo-and-packages.md` (world sits at the bottom of the domain DAG; turn is imported by no other domain package).

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_world_test_no_upstream_domain_deps.dart` | Checker and CLI |
| `tool/ct_repo_lint_manifest.yaml` (`repo.world_test_no_upstream_domain_deps`) | Rule registration |

## Scan scope

Every `.dart` file under `packages/colonizethis_world/test/**`, including support. Package keys `colonizethis_logic` and `colonizethis_turn` in `packages/colonizethis_world/pubspec.yaml`.

## Acceptance criteria

- Given a file under `packages/colonizethis_world/test/**` that contains `import 'package:colonizethis_logic/` or `import 'package:colonizethis_turn/`, when the checker runs, then the checker fails and names that file's repo-relative path.
- Given `packages/colonizethis_world/pubspec.yaml` lists `colonizethis_logic` or `colonizethis_turn` as a package key, when the checker runs, then the checker fails and names the pubspec path.
- Given the current world test tree has no such imports and the world pubspec does not list those packages, when the checker runs, then the checker exits `0`.
