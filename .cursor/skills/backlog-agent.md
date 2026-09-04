# Backlog agent shell

Shared by `backlog-review-agent`, `backlog-refine-agent`, `backlog-verify-agent`, and `backlog-accept-agent`.

`backlog-implement-agent` is different (multi-issue throughput) and does not use this shell.

## Select

```bash
gh issue list --state open --label "<source-label>" --limit 100 --json number,title,url,labels,updatedAt
```

- Prefer oldest `updatedAt` unless the user specifies another order.
- A user-supplied issue number/URL overrides auto-selection if the issue is open and carries `<source-label>`; otherwise confirm with the user.
- If none match, report that and stop.

## Run the child skill

Read and apply the child skill **strictly**. Do not weaken or re-implement it here.

## Relabel

Remove `<source-label>` and add exactly one destination label (pass vs fail as defined by the calling skill). Follow [shared.md](shared.md) label-edit rules.

## Chat output

Issue number/title/URL, decision, comment/body confirmation, label transition.

## Guardrails

- Exactly one issue per run unless the user requests batching.
- Conventions in [shared.md](shared.md) (never close issues; `gh` fallback).
