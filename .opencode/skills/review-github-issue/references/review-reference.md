# Reference: Issue review (purpose ↔ method) and optional repo trace

Use this reference when **`review-github-issue`** needs a **conditional** repo/SPEC/test trace: only to show that a **proposed method** in the issue **cannot satisfy** the issue’s **stated purpose** (architecture boundaries, SPEC-first conflicts, missing assumed hooks). Full **acceptance criteria ↔ implementation ↔ tests** mapping for closure is **`verify-github-issue`**, not this skill.

## Finding the purpose (SPEC structure)

- **Game specs** (`SPEC/game/`): mechanics, units, combat, economy, research, diplomacy
- **Program specs** (`SPEC/program/`): technical architecture, UI wiring, tool execution
- **AI specs** (`SPEC/ai/`): AI behavior and planning
- **UI specs** (`SPEC/ui/`): layout, widgets, wireframes

## Key rules for gap analysis

| Rule | File | What it enforces |
|------|------|------------------|
| SPEC-first | `.cursor/rules/colonizethis-spec-required.mdc` | No behavior outside GDD/TDD; extend SPEC before implementing |
| Core principles | `.cursor/rules/colonizethis-core-principles.mdc` | Dart/Flutter/Flame separation, thin screens |
| Coverage | `.cursor/rules/colonizethis-testing.mdc` | 90% logic/ai/map; 80% elsewhere |
| Acceptance criteria | `.cursor/rules/colonizethis-acceptance-criteria.mdc` | Given–When–Then, testable AC quality |
| Logging | `.cursor/rules/colonizethis-logging-file.mdc` | `basic_logger_file` for file sinks |

## Tracing implementations

```bash
# Find relevant files by name patterns
find lib -name "*.dart" | xargs grep -l "TargetClass\|target_method"

# Find tests for a file
find test -name "*.dart" | xargs grep -l "TargetClass"

# View recent commits touching files
git log --oneline -20 --all -- <file>

# Search for SPEC references
grep -r "SPEC\|GDD\|TDD" --include="*.md" <dir>
```

## gh commands for issue review

```bash
# View issue with comments
gh issue view <n> --json title,body,labels,state,url,comments

# List issues by label
gh issue list --label "<label>" --state open

# Add comment
gh issue comment <n> --body "<markdown>"
```
