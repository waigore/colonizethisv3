---
name: accept-github-issue
description: |-
  Executes product acceptance on one explicitly specified GitHub issue (number or URL) and posts an evidence-backed ACCEPT/REJECT comment via gh; never relabels or closes. Gameplay/UI issues: run the issue's ACs in the app on macOS/Linux via Flutter MCP/DTD driver tools (dart_launch_app, dart_flutter_driver, screenshots) with integration_test and headless CLI fallback. Refactor issues: accept as-is once verified — a passing verification comment is the evidence; no re-testing or diff audit at acceptance. Art issues: built-in vision inspection of generated assets for quality and aesthetic fit vs shipped art. Use when the user gives an issue and asks to accept it or run acceptance.

  Examples:
  - user: "Accept #4062" → drive the app through the CtDropdown ACs, screenshot proof, post ACCEPT/REJECT
  - user: "Run acceptance on issue #4117" → refactor: confirm passing verification + merged on dev, post ACCEPT
  - user: "Check whether #1819's road tiles pass" → vision-inspect atlases vs ACs and peer tilesets
---

**Thin Grok shim** (repo `.grok/skills/`).

Source of truth: `.cursor/skills/accept-github-issue/SKILL.md`

Read the full file and follow it exactly.
Also read: `.cursor/skills/accept-github-issue/reference.md`.
