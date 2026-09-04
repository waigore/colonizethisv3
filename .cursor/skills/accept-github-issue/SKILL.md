---
name: accept-github-issue
description: |-
  Executes product acceptance on one explicitly specified GitHub issue (number or URL) and posts an evidence-backed ACCEPT/REJECT comment via gh; never relabels or closes. Gameplay/UI issues: run the issue's ACs in the app on macOS/Linux via Flutter MCP/DTD driver tools (dart_launch_app, dart_flutter_driver, screenshots) with integration_test and headless CLI fallback. Refactor issues: accept as-is once verified — a passing verification comment is the evidence; no re-testing or diff audit at acceptance. Art issues: built-in vision inspection of generated assets for quality and aesthetic fit vs shipped art. Use when the user gives an issue and asks to accept it or run acceptance.

  Examples:
  - user: "Accept #4062" → drive the app through the CtDropdown ACs, screenshot proof, post ACCEPT/REJECT
  - user: "Run acceptance on issue #4117" → refactor: confirm passing verification + merged on dev, post ACCEPT
  - user: "Check whether #1819's road tiles pass" → vision-inspect atlases vs ACs and peer tilesets
---

# Accept a GitHub issue (ColonizeThis)

Issue **number** or **URL**. If only a username is given, ask for the issue. Queue + relabel: [backlog-accept-agent](../backlog-accept-agent/SKILL.md). Conventions: [shared.md](../shared.md). Cookbook: [reference.md](reference.md).

## Policy

Accept only on **latest `origin/dev`**. **`gh issue comment` only** — never relabel/close (that is `backlog-accept-agent`).

**Hard-fail** (never **ACCEPT**):

- Any AC without executed evidence in the comment (reading code is not evidence).
- Work not merged on `origin/dev`.
- User-visible AC without in-app screenshot proof; UI-visual AC whose screenshot shows it unmet.
- Refactor issue without a passing **Verification** comment (Complete), or `dev` drifted from what was verified.
- Art that fails the vision checklist in reference.md §C.
- Relevant suite red on `dev`; next-turn ACs over the 15 s budget (`colonizethis-turn-resolution-budget.mdc`).
- Touched game-app surface over 1 s or left mounted (`colonizethis-ui-surface-budget.mdc`). Grandfathered untouched overflows exempt. Refactor-only issues stay on the verification comment.

## Workflow

1. `gh issue view <n> --json title,body,labels,state,url` — open.
2. Classify (apply a second procedure when ACs demand it):

   | Category | Signals | Method |
   |----------|---------|--------|
   | **Refactor** | `refactor` label; “byte-identical” / “no UX change” | Verification-based — reference.md §B |
   | **Art generation** | Generated PNGs/atlases, PixelLab, style/seam ACs | Vision + contract tests — §C |
   | **Gameplay / UI** | Default | In-app AC execution — §A |

3. `git fetch origin && git checkout dev && git pull` — unmerged → **REJECT**.
4. Common gates (skip for refactor — the verification comment is the evidence): `melos run test_app`; package tests; `dart run tool/ct_repo_lint.dart` if lint gates changed. A new red suite on clean `dev` blocks acceptance.
5. Execute the category procedure. Every AC → at least one `PASS <evidence>` / `FAIL <observed vs expected>`.
6. Post one comment:

```markdown
**Acceptance**

Category: [Gameplay/UI | Refactor | Art generation]
`dev` @ `<sha>` — [app driven on macos|linux | verification review (refactor) | vision inspection]

| AC | Result | Evidence |
|----|--------|----------|
| <AC> | ✅ PASS / ❌ FAIL | <cmd / screenshot / vision note> |

Visual proof (when applicable):

![<ac>](https://gist.githubusercontent.com/OWNER/GIST_ID/raw/<file>.png)

Gates: `melos run test_app` ✅ · `ct_repo_lint` ✅ · <package tests> ✅

Outcome: **ACCEPT** — all ACs pass on merged dev.
(or: **REJECT** — gaps: 1) … ; follow-ups: …)
```

Driving UI: `colonizethis-e2e-ui-stability.mdc`. If Flutter MCP/DTD is unavailable, fall back to `flutter test integration_test -d macos|linux` + widget/golden suites and say so; an unexecutable AC is a REJECT gap, never a silent PASS. Clean up `tmp/accept-issue-<n>/` after posting.
