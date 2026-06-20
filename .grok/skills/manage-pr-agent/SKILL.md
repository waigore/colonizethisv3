---
name: manage-pr-agent
description: Keeps open pull requests moving through CI and GitHub workflows in an orderly manner. Enforces one open PR per GitHub issue (via consolidate-prs) and maintains a running-CI quota of 2 PRs (both floor and ceiling) by pausing excess via `[skip ci]` empty commits **and cancelling** their in-flight `pull_request` runs (before and after the skip commit). Whenever the quota has headroom and any open PRs exist, fills it by any means necessary: resuming paused PRs, updating mergeable-but-behind PR branches against base, and unblocking stalled PRs via fix-pr (older PRs first). Performs actions once and then ends the run without waiting for merges, CI, or unblock confirmation. Use when the user asks to tidy, throttle, unblock, or generally manage in-flight PRs.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/manage-pr-agent/SKILL.md`

Read the full file. Strictly apply its required dependencies (consolidate-prs + fix-pr), non-negotiables, 4-phase workflow (discover, consolidate, maintain quota of 2, end), and detailed output report format. Never wait for CI/merges.
