---
name: improve-ux-agent
description: Autonomously runs suggest-player-ux-improvements then files one GitHub issue via create-github-issue with no user clarifications. Use when asked to improve UX, scout and file a UX issue, or run improve-ux-agent.
---

# Improve UX Agent (ColonizeThis)

Autonomous pass: one filed issue, **no** clarification Q&A. Conventions: [shared.md](../shared.md).

1. Apply [suggest-player-ux-improvements](../suggest-player-ux-improvements/SKILL.md) end-to-end. If the user named a domain/lens, use it; otherwise pick. Produce the brief, then continue (do not stop at “Next step for the user”).
2. File via [create-github-issue](../create-github-issue/SKILL.md) **skipping** that skill’s mandatory numbered clarifications. Map the brief onto that issue template. One primary issue; dependents stay in the body.

Do not implement. Do not re-propose `rejected` UXDs (child skill). Chat: domain + title, issue URL or paste-ready draft.
