---
name: review-github-issue
description: |-
  Reviews a GitHub issue for coherence between its stated purpose and its proposed approach (design, scope, ACs). Produces a consolidated comment: primary focus is purpose↔method gaps and internal contradictions; code/spec/test evidence only when needed to show the proposed method cannot satisfy the purpose. Use before implementation; use verify-github-issue for AC↔implementation/SPEC/tests verification posted on the issue.

  Examples:
  - user: "Review issue #42" → state purpose, assess whether the proposed method plausibly achieves it, flag internal gaps; repo evidence only if method cannot satisfy purpose
  - user: "Audit this bug report" → extract goal vs proposed fix; flag mismatches, missing how, contradictions in the text
  - user: "Find gaps in issue before starting work" → purpose–method alignment and thin-issue contradictions first; defer full AC→code mapping to verify
  - user: "Triage this issue" → clarify purpose, scope, and whether the described approach hangs together
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/review-github-issue/SKILL.md`

Read the full file (including its boundary table vs verify-github-issue, workflow, priority framing, and output template). Follow the non-negotiables and "primary analysis first, conditional deep trace only when needed" rule exactly. Note its sync comment with the opencode copy is preserved in the source.
