## Purpose

Reduce irrelevant rule overlays by defining one routing map for rule applicability and precedence, while preserving normative policy text in `.cursor/rules/*.mdc`.

## Rule Inventory

| Rule file | Policy owner |
|---|---|
| `colonizethis-spec-required.mdc` | SPEC governance |
| `colonizethis-core-principles.mdc` | Architecture and code standards |
| `colonizethis-logging-file.mdc` | Logging standards |
| `colonizethis-logic-ai-decoupling.mdc` | Package-boundary governance |
| `colonizethis-turn-resolution-budget.mdc` | Turn-resolution performance governance |
| `colonizethis-tools.mdc` | Tooling workflow |
| `colonizethis-testing.mdc` | Test policy and coverage |
| `colonizethis-e2e-ui-stability.mdc` | E2E UI stability |
| `colonizethis-ui-design.mdc` | UI conventions |
| `colonizethis-component-structure.mdc` | Code organization |
| `colonizethis-code-review.mdc` | Review thresholds |
| `colonizethis-lifecycle.mdc` | Flutter/Flame lifecycle |
| `colonizethis-assets.mdc` | Asset and pubspec conventions |
| `colonizethis-acceptance-criteria.mdc` | SPEC acceptance criteria quality |

## Applicability Matrix (Before -> After)

| Context | Before applied rules (observed) | After applied rules (targeted) | Change intent |
|---|---|---|---|
| Generic Dart implementation in `app/lib/**` | always-applied + `component-structure` + `code-review` + `lifecycle` + `assets` via broad `**/*.dart` | always-applied + `component-structure` + `code-review` (plus targeted overlays only) | Remove lifecycle/asset over-application from default implementation flow |
| Flutter widget/UI work (`**/lib/widgets/**`, `**/lib/ui/**`) | above set + `ui-design` | always-applied + `ui-design` + targeted `component-structure`/`code-review` + `lifecycle` | Keep UI constraints while applying lifecycle only in lifecycle-relevant paths |
| Tests (`**/*_test.dart`, `**/test/**`, `**/integration_test/**`) | testing/e2e + broad Dart overlays | testing/e2e first; general Dart overlays apply only where glob-matched | Prioritize test directives and reduce unrelated guidance |
| Asset and pubspec edits (`**/assets/**`, `**/pubspec.yaml`) | `assets` plus broad Dart overlays | `assets` focused guidance + always-applied baseline only | Prevent non-asset directive bleed |
| Tooling facade code (`tool/**`) | `tools` plus broad overlays | `tools` primary + targeted structural/review overlays | Preserve tooling rules and remove unrelated overlays |
| Logic <-> AI boundary work (`packages/colonizethis_logic/**`, `packages/colonizethis_ai/**`) | always-applied decoupling + multiple broad overlays | always-applied decoupling + targeted path overlays only | Preserve strict decoupling while reducing collateral directives |
| OpenCode skill docs (`.opencode/skills/**`) | duplicated routing prose in references | references point to this index + source `.mdc` files | Avoid duplicated normative summaries |

## Precedence Model

1. Always-applied rules are baseline for every task.
2. Context-specific rules apply by frontmatter `globs`.
3. If two context rules conflict, the more specific rule/path takes precedence.
4. Normative policy text remains authoritative only in source `.mdc` files.

## Non-Duplication Contract

- `AGENTS.md` and `.opencode/skills/**/references/*.md` must not restate normative policy text from `.mdc` files.
- These documents may summarize routing, list rule files, and link to authoritative sources.
- Any policy wording changes must be made in the corresponding `.mdc` file, not in routing pointers.

## Change Protocol

When adding or changing a rule:

1. Update the rule file under `.cursor/rules/`.
2. Update this routing index matrix and inventory.
3. Run `dart test test/check_rule_routing_test.dart`.
4. Ensure references (`AGENTS.md`, OpenCode docs) remain pointer-only and non-duplicative.
