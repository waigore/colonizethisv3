# CI and rules (reference)

Routing (which `.mdc` applies): [`.cursor/rules/routing-index.md`](../../../rules/routing-index.md). Policy text stays in the `.mdc` files.

Player-app UI structure: `colonizethis-ui-documentation.mdc` + `document-app-ui`. Style: `colonizethis-ui-design.mdc`.

## Extension points

Primary workflow: `.github/workflows/quality.yml`.

| Area | Typical extension |
|------|-------------------|
| Repo conventions | `dart run tool/ct_repo_lint.dart` — `tool/ct_repo_lint_manifest.yaml` |
| Long `switch` / string dispatch | `dart tool/check_long_string_switches.dart` |
| Domain exceptions | `packages/colonizethis_exception_lint` |
| AST policy tests | `test/check_*_test.dart` in the `quality` job |
| App analyze | `flutter analyze` (errors only) |
| Coverage | `tool/check_coverage_threshold.sh` |

Prefer, in order: analyzer / `custom_lint` → `ct_repo_lint` manifest → small `tool/*.dart` + `check_*` test. Do not propose a full integration run as the only enforcement for a style rule.
