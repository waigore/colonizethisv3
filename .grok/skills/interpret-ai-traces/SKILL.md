---
name: interpret-ai-traces
description: Interprets ColonizeThis full-AI turn-trace JSON (from `run_observer_game` or app/ctdev exports) to explain why a deterministic AI emitted specific orders and to spot performance bottlenecks. Use when the user supplies a merged turn trace, asks why the AI did/did not do X on turn N, asks why a GP chose a goal/phase/target, asks why orders were suppressed, or wants to optimize next-turn resolution against the 15-second budget.
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/interpret-ai-traces/SKILL.md`

Read the full file (including all required SPEC sections and the step-by-step behavior + perf workflows). Follow the anti-patterns, quick reference, and final conclusion format exactly.
