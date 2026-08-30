---
name: accept-github-issue
description: Executes product acceptance on one explicitly specified GitHub issue (number or URL) and posts an evidence-backed ACCEPT/REJECT comment via gh; never relabels or closes. Gameplay/UI issues run ACs in the app on macOS/Linux via Flutter MCP/DTD driver tools (integration_test/headless CLI fallback); refactor issues are accepted as-is once verified (passing verification comment — no re-testing); art issues via built-in vision inspection vs shipped-art aesthetics.
---

# Accept a GitHub issue (OpenCode)

## Source of truth

Use **`.cursor/skills/accept-github-issue/SKILL.md`** and **`reference.md`** as the authoritative workflow, hard-fail rules, category procedures (in-app AC execution / diff-invariance / vision inspection), comment template, and command cookbook.

## OpenCode adaptation

When running in OpenCode:

- Read both Cursor files in full before accepting.
- Require an explicit issue number/URL; the issue must be open. To pick from the `backlog:acceptance` queue and relabel, use `backlog-accept-agent` instead.
- Accept only on **latest `origin/dev`** (`git fetch && git checkout dev && git pull`).
- Drive the app with the `dart_*` MCP tools (`dart_list_devices` → `dart_launch_app` → `dart_connect_dart_tooling_daemon` → `dart_get_widget_tree` / `dart_flutter_driver` / screenshots); fall back to `flutter test integration_test -d macos|linux` and headless CLIs when MCP tools are unavailable, and say so in the comment.
- Gameplay/UI: apply the standing 1 s game-app surface budget + unmount check from the Cursor skill even when the issue ACs omit it.
- Inspect generated art by reading PNGs directly (built-in vision) per the reference.md §C checklist.
- Refactor issues: confirm a passing **Verification** comment (Complete outcome) and that `dev` matches the verified state per reference.md §B — do **not** re-run suites or audit the diff at acceptance.
- Post **`gh issue comment` only** — never relabel, close, or change milestones.

## Required references

Before execution, read:

- `.cursor/skills/accept-github-issue/SKILL.md`
- `.cursor/skills/accept-github-issue/reference.md`
