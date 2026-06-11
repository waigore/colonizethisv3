# Turn resume entry points — config-based dispatch (repo lint)

**SPEC/program** — defines the parameter contract for the Diplomacy-phase
resume entry points in `packages/colonizethis_turn` and the repository lint
gate (`repo.turn_resume_param_budget`) that keeps them slim.

## Motivation

Turn resolution can pause at the Diplomacy phase for blocking human input
(`SPEC/program/turn-resolution-phases.md` § Blocking human input). The app
collects decisions and resumes via one of four entry points:

- `resumeTurnResolutionWithOvertureDecisions`
- `resumeTurnResolutionWithFtpDecisions`
- `resumeTurnResolutionWithInterventionDecisions`
- `resumeTurnResolutionWithCallToArmsDecisions`

These functions re-enter resolution at `TurnPhase.diplomacy` with identical
parameter forwarding, differing only in which decision list they carry.
Previously each wrapper re-declared the full resolver parameter list (~14
parameters) and forwarded them one by one through a shared private dispatch.
Adding a resolver parameter required editing every wrapper, and the duplicated
signatures were a maintenance hazard (Refs #3416).

The resolver already bundles its inputs in `TurnResolverConfig`
(consumed by `resolveTurnForGameWithConfig`). The resume entry points therefore
take a single `TurnResolverConfig config` plus only the resume-specific
arguments (`game`, the decision list, and `pendingOvertures` for the overture
variant). The shared private dispatch overrides `startFromPhase` and the one
decision list via `TurnResolverConfig.copyWith`. A new resolver parameter is
added to `TurnResolverConfig` once and flows through automatically.

## Contract

- Each public `resumeTurnResolutionWith*Decisions` entry point accepts a
  required `TurnResolverConfig config` and forwards it unchanged except for the
  `startFromPhase` and decision-list overrides applied by the shared dispatch.
- The supplied `config` must match the configuration used for the original
  `resolveTurnForGameWithConfig` / `resolveTurnForGame` call (orders, topology,
  tile maps, default assignments, callbacks).
- The shared dispatch always re-enters at `TurnPhase.diplomacy` and sets exactly
  the decision list belonging to the calling wrapper; other decision lists
  remain as carried by `config` (normally unset on resume).
- Behaviour is unchanged versus the previous individually-threaded parameters:
  identical `config` inputs and decisions produce identical results.

## Lint gate

A `resumeTurnResolution*` declaration (public wrappers and the private shared
dispatch) must declare at most `turnResumeMaxNamedParams` (**6**) named
parameters. The public overture wrapper carries 4 (`game`, `pendingOvertures`,
`decisions`, `config`); the widest legitimate declaration is the private shared
dispatch `_resumeTurnResolutionWithDiplomacyDecisions` with 6 (`game`, `config`,
and the four optional decision lists). Re-introducing an individually threaded
parameter list (~14) pushes a declaration well over budget and fails the gate.

### Source of truth

| Artifact | Role |
|----------|------|
| `tool/check_turn_resume_param_budget.dart` | Checker and CLI entrypoint |
| `tool/ct_repo_lint_manifest.yaml` (`repo.turn_resume_param_budget`) | Rule registration |

### Scan scope

The checker scans files returned by `collectRepoLintDomainDartFiles` and
evaluates only those whose repo-relative path begins with
`packages/colonizethis_turn/lib/`. Generated and test files stay excluded by the
shared repo-lint scan contract.

### Declaration detection and counting

A declaration is recognised by the function name `resumeTurnResolution<...>`
immediately followed by a named-parameter block opener `({`. Call sites pass
named arguments (`(\n game: ...`) and never match the `({` form, so only
declarations are evaluated. The parameter count is the number of top-level
named parameters; commas nested in generic arguments (`<...>`), function-type
parameter lists (`(...)`), collection literals (`[...]`), or nested record
groups (`{...}`) are ignored, and a trailing comma does not inflate the count.

## Acceptance criteria

- Given the file `packages/colonizethis_turn/lib/src/turn/turn_resolver.dart`
  with all `resumeTurnResolution*` declarations forwarding a single
  `TurnResolverConfig` (≤ 6 named parameters each), when the checker runs, then
  the checker passes with exit code 0.
- Given a Dart file under `packages/colonizethis_turn/lib/` declaring a
  function `resumeTurnResolutionWithXDecisions` with 14 named parameters, when
  the checker runs, then the checker fails with exit code 1 and the violation
  text names that file's repo-relative path, the 1-based line of the
  declaration, the function name, and its parameter count.
- Given a Dart file under `packages/colonizethis_turn/lib/` that contains a
  call `resumeTurnResolutionWithOvertureDecisions(game: g, decisions: d,
  config: c)` (a call, not a declaration), when the checker runs, then the
  checker does not treat the call as a declaration and does not fail because of
  it.
- Given a `resumeTurnResolution*` declaration whose only function-type
  parameter is `void Function(int, int)? cb` (commas nested inside the
  function-type parameter list), when the checker runs, then the checker counts
  that parameter once and does not count the nested commas.
- Given a Dart file outside `packages/colonizethis_turn/lib/` declaring a
  `resumeTurnResolutionWithXDecisions` function with 20 named parameters, when
  the checker runs, then the checker does not evaluate that file for this rule
  and does not fail because of it.
