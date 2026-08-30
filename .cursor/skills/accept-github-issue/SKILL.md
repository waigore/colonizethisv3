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

## When this applies

Issue **number** or **URL** is given. If only a GitHub username is given, ask for the issue number/URL. To pick from the `backlog:acceptance` queue instead, use **`backlog-accept-agent`**.

## Policy

Follow **[AGENTS.md](../../../AGENTS.md)** and **[CONTRIBUTING.md](../../../CONTRIBUTING.md)**. SPEC-first. Verify only on **`origin/dev`**.

**Hard-fail** (never **ACCEPT**):

- Any AC without **executed evidence** in the comment (test output, in-app screenshot, CLI assertion, or diff-audit finding). Reading code is not acceptance evidence.
- Work not merged on **`origin/dev`**.
- User-visible AC without **in-app screenshot proof** (driven app or passing e2e scenario capturing the state); UI-visual AC whose screenshot shows it unmet.
- Refactor issue without a passing **Verification** comment (outcome **Complete**) on the issue, or whose merged state on `dev` has drifted from what was verified.
- Art issue whose assets fail the vision checklist (placeholder look, seam breaks, off-palette vs peers, wrong geometry vs contract).
- Any relevant suite red on `dev`; next-turn ACs exceeding the **15 s budget**.
- **Gameplay/UI** (standing; **not** AC-gated): a touched **game-app** panel, dialog, or overlay that opens over **1 000 ms** for required content (calcs, minimaps, Yarn) or that leaves unused dialogs/widgets/`FlameGame`s mounted after close (`colonizethis-ui-surface-budget.mdc`). Refactor-only issues stay on the verification comment.

**Never** change labels, milestones, or issue state — **`gh issue comment` only** (label transitions belong to `backlog-accept-agent`).

## Workflow

1. `gh issue view <n> --json title,body,labels,state,url` — issue must be open.
2. **Classify** (apply a second procedure when ACs demand it, e.g. UI feature shipping generated art):

   | Category | Signals | Method |
   |----------|---------|--------|
    | **Refactor** | `refactor` label; "byte-identical" / "no UX change" / "behavior-preserving" ACs | Verification-based acceptance (no re-testing) — reference.md §B |
   | **Art generation** | ACs reference generated PNGs/atlases under `app/assets/**`, PixelLab pipelines, style/seam criteria | Vision inspection + contract tests — §C |
   | **Gameplay / UI** | Default: player-visible behavior, screens, game rules, setup pipeline, AI | In-app AC execution — §A |

3. `git fetch origin && git checkout dev && git pull` — unmerged/local-only work → **REJECT**.
4. **Common gates** (gameplay/UI and art issues; **refactor issues skip this** — the gates recorded in the passing verification comment are the evidence): `melos run test_app`; target package tests for `packages/<name>/` issues; `dart run tool/ct_repo_lint.dart` when the issue changes lint gates. A red suite not pre-existing on clean `dev` blocks acceptance.
5. **Execute the category procedure** per **[reference.md](reference.md)**: derive one executable case per AC (Given → setup, When → driver actions, Then → widget-tree/screenshot assertion); record per-AC `PASS <evidence>` / `FAIL <observed vs expected>`. Every AC maps to at least one executed procedure.
6. Post **one** consolidated comment (`gh issue comment <n> --body-file …`):

   ```markdown
   **Acceptance**

   Category: [Gameplay/UI | Refactor | Art generation] (mixed: …)
   `dev` @ `<sha>` — [app driven on macos|linux | verification review (refactor) | vision inspection]

   | AC | Result | Evidence |
   |----|--------|----------|
   | <AC, shortened> | ✅ PASS / ❌ FAIL | <test cmd / screenshot / diff finding / vision note> |

   Visual proof (when applicable):

   ![<ac>](https://gist.githubusercontent.com/OWNER/GIST_ID/raw/<file>.png)

   Gates: `melos run test_app` ✅ · `ct_repo_lint` ✅ · <package tests> ✅

   Outcome: **ACCEPT** — all ACs pass on merged dev.
   (or: **REJECT** — gaps: 1) … 2) …; required follow-ups: …)
   ```

## Tools

`gh` (issue view/comment, gist create, pr diff), Flutter MCP/DTD tools (`dart_list_devices`, `dart_launch_app`, `dart_connect_dart_tooling_daemon`, `dart_get_widget_tree`, `dart_flutter_driver`, `dart_get_app_logs`, `dart_stop_app`), `cd app && flutter test`, `melos run test_app`, `dart run init_game` / `dart run run_observer_game`, built-in vision (Read on PNGs), `rg`, `curl -sfI`. Cookbook: [reference.md](reference.md).

## Guardrails

- Evidence or it didn't happen: every PASS references an executed artifact.
- Driving UI: stable keys, visibility-first interactions per `colonizethis-e2e-ui-stability.mdc`; no fixed-coordinate taps without a deterministic target.
- If the Flutter MCP/DTD toolchain is unavailable, fall back to `flutter test integration_test -d macos|linux` + widget/golden suites and say so in the comment; an AC that cannot be executed by any available tool is a REJECT gap ("needs manual acceptance"), never a silent PASS.
- Clean up run artifacts (`tmp/accept-issue-<n>/`, logs) after posting per `colonizethis-agent-run-cleanup.mdc`.
- If `gh` is unavailable or fails, return the prepared comment for manual posting.
