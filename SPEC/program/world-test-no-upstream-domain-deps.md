# World tests — no upstream domain deps (repo lint)

**SPEC/program** — repository lint gate that forbids `packages/colonizethis_world/test/**` (including `world_test_support/`) from importing `colonizethis_logic`, `colonizethis_turn`, or `colonizethis_orders`, and forbids those packages as world `pubspec.yaml` dependencies (Refs #4515). Companion to `repo.world_no_logic_deps` (lib-only) and `SPEC/program/repo-and-packages.md` (world sits at the bottom of the domain DAG; turn is imported by no other domain package; orders already depends on world).

Work-target ids (`kWorkTarget*`) stay in `colonizethis_orders` (`SPEC/program/logic-package-split-phase0.md`). World tests that need a `CurrentWork.workTarget` fixture use a **non-canonical** string, not `'build_road'` / `kWorkTargetBuildRoad`, so `repo.work_target_constants` stays green without a world→orders cycle.

## Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_world_test_no_upstream_domain_deps.dart` | Checker and CLI |
| `tool/ct_repo_lint_manifest.yaml` (`repo.world_test_no_upstream_domain_deps`) | Rule registration |

## Scan scope

Every `.dart` file under `packages/colonizethis_world/test/**`, including support. Package keys `colonizethis_logic`, `colonizethis_turn`, and `colonizethis_orders` in `packages/colonizethis_world/pubspec.yaml`.

## Acceptance criteria

- Given a file under `packages/colonizethis_world/test/**` that contains `import 'package:colonizethis_logic/`, `import 'package:colonizethis_turn/`, or `import 'package:colonizethis_orders/`, when the checker runs, then the checker fails and names that file's repo-relative path.
- Given `packages/colonizethis_world/pubspec.yaml` lists `colonizethis_logic`, `colonizethis_turn`, or `colonizethis_orders` as a package key, when the checker runs, then the checker fails and names the pubspec path.
- Given the current world test tree has no such imports and the world pubspec does not list those packages, when the checker runs, then the checker exits `0`.
