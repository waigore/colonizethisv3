# Agentic prompt: GDD scenario coverage (Coder)

**SPEC/project** — Instructions for the **coder** agent only. The verifier uses a separate prompt: [agentic-gdd-verifier.md](agentic-gdd-verifier.md). This prompt defines how the coder incrementally extends sim_scenarios and game logic so that the implementation is verified against the GDD (SPEC/game). Use together with the coverage tool and mapping defined in [gdd-scenario-coverage.md](gdd-scenario-coverage.md).

---

## Role: Coder only

**You are the coder.** You change game logic, add or extend scenarios, and update the coverage mapping. You do **not** perform the verifier’s audit (line-by-line check of covered specs and writing of `verifierIssues`). When you see `verifierIssues` for a spec, fix the implementation or assertions and then clear or update that list.

---

## Goal

Ensure every testable acceptance criterion (AC) in `SPEC/game` has at least one `sim_scenarios` scenario. Work on **one GDD spec at a time**: pick its ACs, align the implementation with the spec if needed, then add or extend scenarios and coverage so the next run can pick another uncovered spec.

---

## Before you start

1. **Read** [gdd-scenario-coverage.md](gdd-scenario-coverage.md) for the coverage approach, mapping file location, and how to run the coverage tool.
2. **Run** the coverage tool from repo root: `melos run check_gdd_coverage`. Note which specs are **uncovered** and which **covered** specs have **verifier issues** (listed in the report).
3. **Choose exactly one** spec for this session:
   - Prefer a **covered** spec that has `verifierIssues` (so you can rectify them), or
   - Otherwise an **uncovered** spec (e.g. the first in the list, or one you are asked to focus on).

---

## Single-session workflow (coder, one spec at a time)

1. **Open the chosen GDD spec** (e.g. `SPEC/game/combat.md`). Read it fully, then locate its **acceptance criteria (ACs)** written as Given–When–Then. If the mapping has **verifierIssues** for this spec, address those first (add missing assertions, fix implementation to match the spec), then re-run scenarios and clear or update the issues in the mapping. Otherwise, select 1–3 concrete ACs or behaviours to cover (e.g. “attacker strength affects casualties”, “province flips to attacker when defender eliminated”).
2. **Check existing code** that implements that behaviour (e.g. combat resolution in colonizethis_logic). If the implementation does not align with the spec, **extend or amend the game logic** so it matches the GDD; then add scenarios that verify the spec. Do not lock in behaviour that contradicts the spec. If the spec is ambiguous, clarify the GDD first, then implement and test.
3. **Add or extend scenarios** under `tool/sim_scenarios/scenarios/`:
   - Reuse existing scenario JSON format (init, setup, turns, assertions). Use fresh init or saved-game init as needed.
   - **Derive Given, When, and Then from the chosen ACs in the GDD**, not from the current implementation—so the scenario detects misalignment.
   - Script the minimal orders needed to trigger the behaviour (e.g. move into enemy province, build unit, run work order).
   - Add assertions that verify the spec’s rules and AC outcomes (owner, unitCount, stockpile, treasury, etc. as in [sim-scenarios.md](../program/sim-scenarios.md)).
4. **Run** the new/updated scenario(s): `melos run sim_scenarios -- --scenario=tool/sim_scenarios/scenarios/<name>.json`. Fix any failures (assertions or scenario structure).
5. **Update the coverage mapping** (see gdd-scenario-coverage.md): add the scenario filename(s) to the entry for the spec you covered. If you resolved verifier issues for this spec, **clear or shorten the `verifierIssues` list** for that entry (use object form `{ "scenarios": [...], "verifierIssues": [] }` if needed). Do not add coverage for other specs in the same session unless they were already in scope.
6. **Run the coverage tool again**: `melos run check_gdd_coverage`. Confirm the spec you targeted is now listed as covered.
7. **Commit** scenario file(s), any logic changes, and the updated coverage mapping with a clear message (e.g. “GDD scenario coverage: combat.md”).

---

## When implementation and spec disagree

**GDD is source of truth.** Extend or amend the game logic so behaviour matches the spec, then add scenarios that verify it. Do not write scenarios that assert incorrect (spec-violating) behaviour. Permitted actions:

- **Amend implementation** in colonizethis_logic (or other packages) to match the GDD. Add or adjust tests (unit/widget) as needed.
- **Update TDD/program specs** (SPEC/program) if the change affects architecture or module contracts.
- **Clarify the GDD** only when the spec is ambiguous or silent on the point; then implement and add the scenario.

Do not leave implementation and spec in conflict; fix the implementation within the same session so the new scenario passes with correct behaviour.

---

## Constraints

- **One spec per session (at most).** Do not attempt to cover multiple GDD specs in one prompt or one PR unless explicitly asked.
- **AC-driven scenarios.** When defining `sim_scenarios`, base Given, When, and Then on the acceptance criteria in the chosen `SPEC/game` document (see `.cursor/rules/colonizethis-acceptance-criteria.mdc`). If ACs are missing or unclear, update the spec and ACs first, then write the scenario.
- **SPEC-first.** Do not add behaviour that contradicts the GDD. If the implementation disagrees with the spec, **change the implementation** to match the spec (and update TDD/program specs if needed); then add the scenario. The agent may extend or amend game logic in colonizethis_logic (or related packages) to achieve alignment.
- **Thin scenarios.** Prefer the smallest init/setup and fewest turns that still verify the spec. One scenario per main behaviour is enough; avoid duplicate coverage for the same rule.
- **Province identity.** Use full province id (regionId|localId) per [world-model-identity.md](../game/world-model-identity.md) and core principles.
- **Logging.** Use Dart `logger` in any new Dart code; no `print` for operational output.

---

## Out of scope for this prompt

- Changing the GDD text beyond clarifications that unblock a scenario.
- Adding new assertion types or new scenario fields without a TDD/spec note (extend [sim-scenarios.md](../program/sim-scenarios.md) or program spec first if needed).
- Covering SPEC/ai or SPEC/ui in this workflow; this prompt is for SPEC/game only.

---

## References

- [gdd-scenario-coverage.md](gdd-scenario-coverage.md) — Coverage approach, mapping file, verifierIssues, tool usage
- [agentic-gdd-verifier.md](agentic-gdd-verifier.md) — Verifier prompt (coder does not follow this; coder rectifies issues the verifier records)
- [sim-scenarios.md](../program/sim-scenarios.md) — Scenario format, assertions, execution
- Colonizethis spec-required rule — SPEC-first; no behaviour that contradicts GDD
