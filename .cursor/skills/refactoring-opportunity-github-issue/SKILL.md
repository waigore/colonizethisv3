---
name: refactoring-opportunity-github-issue
description: Analyzes `app/` or one `packages/*` workspace package on the latest `origin/dev` baseline for refactoring opportunities using ColonizeThis `.cursor/rules` (plus sound Dart/Flutter practice), de-duplicates against open GitHub issues, proposes focused CI enforcement (AST-first; extend existing gates before adding new ones), and produces a structured GitHub issue another developer can implement. Use when the user asks for refactor scouting, package-level tech-debt triage, or a filing-ready issue from evidence-based findings scoped to app or a package.
---

# Refactoring opportunity → GitHub issue (ColonizeThis)

## Scope (strict)

- **In scope targets only:** repository root `app/` **or** a single package under `packages/<name>/` (Melos/Dart package). Do **not** treat `tool/`, `widgetbook_host/`, `ctdev/`, `pytool/`, or repo-wide multi-root sweeps as the primary target for this skill; if the user names something else, ask them to pick `app` or one `packages/<name>` package (or run the workflow twice).
- **Read-only analysis** until the issue is filed: search/read code, specs, CI config, and existing checkers; do **not** refactor code in the same pass unless the user explicitly switches to implementation.
- **Issue shape:** Follow the title/body structure and quality bar from **`.cursor/skills/create-github-issue/SKILL.md`**, adapted for **maintenance/refactor** work (see “Issue body template” below). Use the same **`gh issue create --body-file`** path when filing; on failure, output full title + body like that skill.

## Workflow

### 1. Lock scope

Confirm:

| Field | Value |
|--------|--------|
| **Target** | `app` **or** `packages/<package>` |
| **Motivation** (optional) | e.g. readability, coupling, testability, performance smell — from user or inferred |

If scope is ambiguous, ask one short question before scanning.

### 1b. Sync to latest `dev` and record baseline (required)

Opportunities must be judged against **current `origin/dev`**, not a stale local branch or feature head.

1. From repo root: `git fetch origin dev` (retry on transient network errors per agent/git policy).
2. Ensure the analysis revision is **`dev` fast-forwarded to `origin/dev`**:
   - If already on `dev`: `git merge --ff-only origin/dev` (or `git pull --ff-only origin dev`).
   - If on another branch: `git checkout dev` then `git merge --ff-only origin/dev` (or equivalent `git pull --ff-only origin dev`).
3. If fast-forward fails (local `dev` has diverged), **stop** and resolve in chat: either reset `dev` to `origin/dev` with explicit user consent for destructive git ops, or analyze from a detached `origin/dev` checkout after `git fetch` — in both cases record the exact **`git rev-parse HEAD`** used.
4. **Record** `HEAD` SHA (short + full) and the fact that it matches `origin/dev` at analysis time. Include this under **Investigation notes** in the drafted issue (e.g. `Analysis baseline: dev @ abc1234`).

Do **not** start codebase analysis (step 3) until this step succeeds or the user explicitly accepts a documented non-`dev` baseline.

### 1c. De-duplicate against open GitHub issues (required)

Before finalizing findings and the issue body, **compare planned themes** to work already tracked so the filing does not duplicate open issues.

1. With GitHub CLI from repo root (repo inferred from `origin`): list open issues, e.g.  
   `gh issue list --state open --limit 200 --json number,title,labels,url`  
   If the list is truncated or the backlog is large, run additional passes (higher `--limit` if supported) and/or `gh search issues` scoped to this repo (`repo:owner/name state:open`) with queries tied to the **target path** (e.g. package name, `app/`, “refactor”, “tech debt”, “lint”, “AppEventBus”) and merge unique hits.
2. For each **candidate duplicate** (similar title or same subsystem/path), run `gh issue view <n>` and skim the body; if the open issue already covers the same opportunity, **drop or narrow** your finding and instead **reference** `#n` in investigation notes (“already tracked”).
3. If **`gh` is missing, not authenticated, or the API fails**, state that plainly in the drafted issue under **Investigation notes** (duplicate check incomplete) and give 1–2 **search strings** the reader should run in GitHub issue search before implementing.

### 2. Load governance context

1. Read **`AGENTS.md`** at repo root for the rule index.
2. For the chosen target path, read **every `.cursor/rules/*.mdc` file whose `globs` / `alwaysApply` plausibly covers that tree** (always-applied rules first, then additive context rules). At minimum for Dart under `app/` or `packages/**`: `colonizethis-spec-required`, `colonizethis-core-principles`, `colonizethis-component-structure`, `colonizethis-code-review`, plus any others that match (e.g. `colonizethis-testing` for tests, `colonizethis-ui-design` for UI paths, `colonizethis-logic-ai-decoupling` when touching logic↔ai boundaries).
3. When behavior or architecture could be normative, spot-check relevant **`SPEC/`** sections (program/game/ui) **read-only** — same SPEC-first instinct as implementation, but do not edit SPEC in this skill unless the user asks.

### 3. Analyze the codebase (evidence-based)

Search and read concrete sites (types, public APIs, large files, cross-imports, duplicated patterns):

- **Project rules:** Tie each finding to a **specific rule file** (and SPEC section if applicable), or label it **general practice** (Dart/Flutter: e.g. unnecessary `dynamic`, over-wide imports, God widgets, tight coupling across layers).
- **Architecture:** Respect boundaries from rules (e.g. logic vs AI, UI vs Flame, `AppEventBus` vs cross-panel callbacks) — flag violations with file paths and a short “why it matters.”
- **Tests:** Note gaps that would make a refactor risky; reference `colonizethis-testing.mdc` expectations for the layer.

Prefer **file:symbol** or **path + pattern** citations over vague advice. Separate **facts** (what the code does) from **recommendations** (what to change).

### 4. CI / enforcement plan (focused)

Before proposing **new** automation:

1. Read **`.github/workflows/quality.yml`** (and `app_tests_cache` analyze steps if relevant) for what already runs.
2. Prefer, in order:
   - **Extend** an existing checker: `tool/ct_repo_lint.dart` + `tool/ct_repo_lint_manifest.yaml`, `tool/check_long_string_switches.dart`, `packages/colonizethis_exception_lint`, or tests under `test/check_*_test.dart` / `tool/` that already gate CI.
   - **Dart analyzer / `custom_lint`** when the rule is expressible without a one-off script.
   - **New** small AST or static script only when the above cannot express the invariant cheaply.

Keep proposals **one concern per check**, fast to run, and scoped to paths under the issue’s target where possible. Explicitly say **“extend X”** vs **“add new job/step”** and name the file(s) to touch.

Details and pointers: [references/ci-and-rules.md](references/ci-and-rules.md).

### 5. Draft the GitHub issue

Use the template below. Title: imperative, ≤~80 chars (e.g. `Refactor <area> in <app|package> for <concise outcome>`).

**Filing:** From repo root, after draft is ready, follow **create-github-issue** §5–6 (`gh issue create`, `--body-file`, fallback body in chat).

## Issue body template

Adapt from create-github-issue: maintenance issues use **N/A** where repro steps do not apply.

```markdown
## Summary
[1–2 sentences: target + outcome]

## Scope
- **Target:** `app` or `packages/<name>`
- **Non-goals:** [what this issue will not change]

## Steps to reproduce
Not applicable (refactoring / maintainability improvement).

## Current behavior
[Observable structure, coupling, or risk — grounded in code paths]

## Expected behavior / target state
[Clearer boundaries, smaller units, better test seams, etc.]

## Investigation notes
- **Analysis baseline:** `dev` @ `<full-or-short-sha>` (synced to `origin/dev` at time of scan)
- **Open issues / de-duplication:** [e.g. “Compared open issues; no overlap for themes A/B” or “Overlaps #42 (subset); this issue covers only …” or “`gh` unavailable; searched: …”]
- **Rules:** [which `.cursor/rules/*.mdc` clauses inform each theme]
- **SPEC:** [paths/sections if behavior/architecture is specified]
- **Code:** [representative files, APIs, dependency directions]
- **Tests:** [existing coverage; what should gain tests after refactor]

## Proposed work (not implemented)
- **Refactors:** [ordered bullets: smallest safe steps first]
- **CI / enforcement:** [extend vs new; AST vs analyzer; files like `quality.yml`, `tool/ct_repo_lint_manifest.yaml`, `test/check_*`]
- **SPEC follow-up:** none | clarification | new section (per spec-required policy)

## Risks / edge cases
- ...

## Suggested acceptance criteria
- [ ] ...
```

## Quality bar

- Actionable for a **different** implementer: enough paths and “done means” to start without re-discovering.
- No drive-by unrelated refactors in the issue text; keep the issue as **focused** as the proposed CI checks.
- If findings are shallow or blocked on product decisions, say so and narrow the issue rather than speculating.

## Related

- Issue filing format and `gh` usage: `.cursor/skills/create-github-issue/SKILL.md`
- Pre-implementation issue coherence: `.cursor/skills/review-github-issue/SKILL.md`
- Post-implementation verification: `.cursor/skills/verify-github-issue/SKILL.md`
