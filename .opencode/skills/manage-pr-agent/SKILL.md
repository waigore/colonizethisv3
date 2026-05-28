---
name: manage-pr-agent
description: Keeps open pull requests moving through CI and GitHub workflows in an orderly manner. Enforces one open PR per GitHub issue (via consolidate-prs) and maintains a running-CI quota of 2 PRs (both floor and ceiling) by pausing excess via `[skip ci]` empty commits, resuming paused PRs, and unblocking stalled PRs via fix-pr (older PRs first) whenever the quota has headroom. Performs actions once and then ends the run without waiting for merges, CI, or unblock confirmation. Use when the user asks to tidy, throttle, unblock, or generally manage in-flight PRs.
---

# Manage PR Agent (ColonizeThis) — OpenCode

This OpenCode skill **defers** to the canonical Cursor skill to avoid drift.

## Read and follow

`.cursor/skills/manage-pr-agent/SKILL.md` (same repository).

That file is normative. It defines:

- Discovery of open PRs with mergeability, check rollup, and head/base
  metadata (single snapshot reused by every later phase).
- One-PR-per-issue enforcement by deferring strictly to
  `.cursor/skills/consolidate-prs/SKILL.md`.
- A single **Maintain CI throughput target of 2** phase (both floor and
  ceiling) that, depending on the current running-CI count `R`:
  - Pauses excess PRs when `R > 2` (cancel in-flight
    `pull_request` / `pull_request_target` runs, then push an empty
    `[skip ci]` commit on the PR's head branch).
  - Fills toward `R == 2` when `R < 2` by either **resuming** a paused
    PR (plain non-skip empty commit on its head branch) or **unblocking**
    a stalled PR via strict `.cursor/skills/fix-pr/SKILL.md`, generally
    oldest `updatedAt` first.
  - No-ops when `R == 2`. Skips the phase entirely when total open PRs
    are fewer than 2.
- Fork-owned head handling (skipped for both pause and resume),
  never-wait policy, and guardrails (no issue closure, no remote branch
  deletion, no required-check bypass, no force-push, no merging).
- Output format with consolidation / CI-throughput (pause + resume +
  unblock) / no-op sections.

If `.cursor/skills/manage-pr-agent/SKILL.md` is unavailable, stop and ask
the user how to proceed — do not improvise a PR-management workflow.
