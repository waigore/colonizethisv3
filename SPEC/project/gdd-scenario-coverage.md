# GDD scenario coverage — approach and tool

**SPEC/project** — Defines how we track and report which GDD specs (SPEC/game) are verified by sim_scenarios, how the verifier records issues for the coder, and how to run the coverage tool.

---

## Roles: Coder vs Verifier

| Role | Prompt | Responsibility |
|------|--------|-----------------|
| **Coder** | [agentic-gdd-scenario-coverage.md](agentic-gdd-scenario-coverage.md) | Add or extend scenarios and game logic so uncovered specs become covered; fix implementation when it disagrees with the spec; **read and rectify verifier issues** in the mapping. |
| **Verifier** | [agentic-gdd-verifier.md](agentic-gdd-verifier.md) | Audit **covered** specs line-by-line; note missing assertions and inconsistencies; **write issues** to the mapping (`verifierIssues`) for the coder to fix. Verifier does not implement or edit scenarios. |

The coder works on **uncovered** specs (and on specs that have `verifierIssues`). The verifier works on **covered** specs only, one at a time, and only updates the mapping with issues.

---

## Purpose

- **Track** which SPEC/game documents have at least one scenario that verifies their rules.
- **Report** covered vs uncovered specs so the coder can pick the next spec to cover.
- **Surface gaps** in covered specs via `verifierIssues` so the verifier can record them and the coder can rectify (add assertions, fix implementation).

---

## Mapping file

**Path:** `SPEC/project/gdd-scenario-coverage.json` (repo root relative).

**Format:** JSON object. Keys = GDD spec path relative to `SPEC/` (e.g. `game/combat.md`). Values are either:

- **Array of strings** — scenario filenames only (legacy). Treated as covered if non-empty. No verifier issues.
- **Object** — `{ "scenarios": ["file.json", ...], "verifierIssues": ["issue one", "issue two"] }`. Same coverage rule: covered if `scenarios` is non-empty. `verifierIssues` is optional; used by the **verifier** to record gaps (missing assertions, inconsistencies). The **coder** reads these and addresses them, then clears or updates the list.

Scenario names are relative to `tool/sim_scenarios/scenarios/`.

Example:

```json
{
  "game/combat.md": {
    "scenarios": ["combat_basic.json"],
    "verifierIssues": [
      "§2 Casualties: no assertion checks casualty count against strength ratio."
    ]
  },
  "game/factions.md": [],
  "game/game-setup.md": ["basic_turn_1.json"]
}
```

- **Empty array** (value `[]`) = spec is not yet covered.
- **Non-empty array** or **object with non-empty `scenarios`** = spec is covered. If the value is an object with a non-empty `verifierIssues` array, the coverage tool prints those issues so the coder can rectify them.

The mapping file must contain an entry for every file under `SPEC/game/*.md`.

---

## Coverage tool

**Name:** `check_gdd_coverage`

**Invocation (from repo root):**

```bash
melos run check_gdd_coverage
```

**Behaviour:**

1. Read `SPEC/project/gdd-scenario-coverage.json`. Each entry’s value may be an array of scenario names or an object `{ "scenarios": [...], "verifierIssues": [...] }`.
2. Discover all `SPEC/game/*.md` files. If the mapping is missing an entry for any of them, treat that spec as uncovered.
3. For each spec in the mapping, **covered** = entry exists and the scenario list (from array or from `object.scenarios`) is non-empty; **uncovered** = entry missing or scenario list empty.
4. Print a short report:
   - Total GDD specs (count of SPEC/game/*.md).
   - Covered count and uncovered count.
   - List of uncovered spec paths (one per line or table) so the **coder** can choose the next target.
   - For each **covered** spec that has a non-empty `verifierIssues` list, print those issues so the **coder** can see and rectify them.
5. Validate that every scenario filename listed in the mapping exists under `tool/sim_scenarios/scenarios/` and warn if missing.

Exit code: 0 if all specs are covered; non-zero if any are uncovered (so CI can enforce coverage growth).

---

## Limitation: file-level coverage can hide misalignment

The tool only checks that each **spec file** has at least one scenario listed. It does **not** verify that:

- Every testable part of the spec (each rule or section) has a scenario or assertion.
- The scenario assertions were derived from the **spec** (expected outcomes from the GDD), not from the current implementation—so a spec can be marked covered even when the implementation violates it in untested cases.
- The listed scenarios actually run and pass; the tool does not execute them.

So a spec can be marked "covered" while parts of it are untested or the implementation is wrong where no assertion looks.

---

## How to uncover partial or false alignment

Use one or more of the following so the process can surface cases where a spec is marked covered but not fully or correctly aligned.

**1. Rule- or section-level coverage (mapping + tool extension)**  
- In the mapping, allow optional **rules** (or section IDs) per spec, each with its own scenario list. Example: `"game/combat.md": { "scenarios": ["combat_basic.json"], "rules": [{ "id": "casualties", "scenarios": ["combat_basic.json"] }, { "id": "province_flip", "scenarios": [] }] }`.  
- The tool then reports **uncovered rules** as well as uncovered specs. A spec is only "fully covered" when every listed rule has at least one scenario.  
- Requires maintaining a list of testable rules per spec (in the mapping or in the GDD, e.g. by convention like `## Rule: ...` or a small manifest).

**2. Spec-first scenario writing (process)**  
- In [agentic-gdd-scenario-coverage.md](agentic-gdd-scenario-coverage.md) the agent is instructed to derive scenario **expected outcomes from the GDD text** first, then run the scenario. If it fails, fix the implementation (or fix the scenario if the spec was misread).  
- That reduces "scenarios written to match current (wrong) behaviour." It does not by itself detect that only part of a spec is tested; combine with rule-level coverage for that.

**3. Run scenarios as part of coverage (CI / optional tool mode)**  
- Optionally run `melos run sim_scenarios` on the scenarios listed in the mapping and report which scenario(s) failed. A spec could be treated as "covered but failing" so the agent knows to fix implementation or scenario.  
- Does not identify which *parts* of the spec are untested; it only catches regressions or wrong assertions.

**4. Periodic audit prompt**  
- Periodically ask an agent to pick a **covered** spec, re-read the GDD, and either (a) confirm every testable rule has an assertion in the listed scenario(s), or (b) add assertions or scenarios for missing rules and fix implementation where it diverges.  
- Can be documented as a separate task in SPEC/project (e.g. "audit covered GDD specs for rule-level alignment").

Implementing (1) gives the tool a way to **uncover** "spec marked covered but these rules have no scenario"; (2)–(4) improve alignment and catch regressions without changing the mapping format.

---

## Agent workflows

**Coder:** See [agentic-gdd-scenario-coverage.md](agentic-gdd-scenario-coverage.md). Run `check_gdd_coverage`, pick one uncovered spec (or a covered spec that has `verifierIssues`), add/extend scenarios and fix implementation, update the mapping, clear or update verifier issues when fixed, re-run the tool, commit.

**Verifier:** See [agentic-gdd-verifier.md](agentic-gdd-verifier.md). Run `check_gdd_coverage`, pick one **covered** spec, audit it line-by-line, record issues in the mapping under `verifierIssues`, commit only the mapping.

---

## References

- [agentic-gdd-scenario-coverage.md](agentic-gdd-scenario-coverage.md) — Coder prompt (one spec at a time)
- [agentic-gdd-verifier.md](agentic-gdd-verifier.md) — Verifier prompt (audit one covered spec at a time)
- [sim-scenarios.md](../program/sim-scenarios.md) — Scenario format and assertions
- Tool implementation: `tool/check_gdd_coverage/`
