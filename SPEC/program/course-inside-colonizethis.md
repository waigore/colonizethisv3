# Inside ColonizeThis — Interactive Course

## Overview

**Purpose:** Turn the ColonizeThis game codebase into a self-contained, browser-based interactive course that teaches non-technical learners (vibe coders) how a turn-based strategy game is architected under the hood.

**Output:** A single HTML file (`course/index.html`) assembled from modular HTML partials. Opens directly in any browser — no build step, no server required.

**Learner persona:** A "vibe coder" who may have built or used the game but has never read its code. They want to understand enough to steer AI coding tools more effectively, debug issues, and make better architectural decisions.

---

## What the Course Covers

**6 modules, ~30 minutes total reading time:**

| # | Module | Key Teachings |
|---|--------|---------------|
| 1 | Your Empire as a Factory | Game concept (Old World/New World), the 13-phase turn cycle, factory metaphor |
| 2 | Meet the Team | Four packages (Models, Logic, AI, Map), the one-way dependency rule (AI→Logic→Models), theater troupe metaphor |
| 3 | The Turn Ticker | TurnResolver orchestration, immutable phases, determinism, phase isolation for debugging |
| 4 | The AI Brain | Deterministic goal-weighted AI, hybrid architecture (Goal Manager→Domain Planners→Tactical AI), seeding without chaos dice, PlayerView constraint |
| 5 | Orders in Action | Human + AI order collection, merge rule (human always wins), order type conflicts, restaurant ticket metaphor |
| 6 | The Fog of War | PlayerView as filtered projection, four visibility levels, AI cannot cheat, prospecting reveals hidden resources |

**Interactive elements per module:**
- Data flow animations (step-by-step packet movement)
- Group chat animations (iMessage-style component conversations)
- Drag-and-drop matching exercises
- Multiple-choice scenario quizzes
- Code↔English translation blocks
- Architecture diagrams with hover descriptions
- Pattern/feature cards

---

## Tech Stack

The course is pure HTML/CSS/JS — no framework, no build-time rendering.

| Asset | Source |
|-------|--------|
| `styles.css` | Pre-built design system (warm palette, typography, interactive element styles) — copy verbatim from skill |
| `main.js` | Pre-built JS engines for animations, quizzes, tooltips — copy verbatim from skill |
| `_base.html` | Shell HTML with course title, accent color, nav dots — customized per course |
| `_footer.html` | 3-line closing stub — copy verbatim from skill |
| `modules/*.html` | One `<section>` partial per module — written manually or by agents |
| `build.sh` | `cat _base.html modules/*.html _footer.html > index.html` — copy verbatim from skill |

---

## File Structure

```
course/
├── index.html          # Assembled output (open this in browser)
├── _base.html          # Customized shell (title, accent, nav dots)
├── _footer.html        # Closing stub
├── build.sh            # Assembly script
├── styles.css          # Design system (from skill)
├── main.js             # Animation/quiz engines (from skill)
└── modules/
    ├── 01-empire-factory.html
    ├── 02-meet-the-team.html
    ├── 03-turn-ticker.html
    ├── 04-ai-brain.html
    ├── 05-orders-in-action.html
    └── 06-fog-of-war.html
```

---

## (Re)Generating the Course

### Prerequisites

- Bash shell
- `course/briefs/00-curriculum.md` — curriculum design with teaching arcs, code snippets, interactive element specs
- Access to the codebase being taught ( ColonizeThis at `colonizethisv3_7/`)

### Step 1: Get the skill reference files

**Primary:** Skill directory (local install)
```
/Users/waigore/.config/opencode/skills/codebase-to-course/references/
```

**Fallback:** GitHub repo (if skill not available)
```bash
git clone https://github.com/zarazhangrui/codebase-to-course /tmp/codebase-to-course
# Reference files are at:
# /tmp/codebase-to-course/references/
```

### Step 2: Set up the course directory

```bash
mkdir -p course/modules course/briefs

# Copy reference files verbatim
cp /path/to/references/styles.css  course/styles.css
cp /path/to/references/main.js     course/main.js
cp /path/to/references/_footer.html course/_footer.html
cp /path/to/references/build.sh    course/build.sh
chmod +x course/build.sh
```

### Step 3: Analyze the target codebase

Explore the codebase to understand:
- Project purpose and tech stack
- Main actors/components and their responsibilities
- Key data flows and architectural patterns
- Real code snippets (5-10 lines, self-contained) for each teaching point

Extract these as **code snippets** in module briefs — writing agents use them verbatim and do NOT re-read the codebase.

### Step 4: Write the curriculum brief

Create `course/briefs/00-curriculum.md` with one section per module:
- Teaching arc (metaphor, opening hook, key insight, "why should I care")
- Pre-extracted code snippets (exact copies from codebase with file:line references)
- Interactive elements checklist with enough detail to build
- Which reference file sections each writing agent needs
- Previous/next module connections

### Step 5: Customize the shell

Edit `course/_base.html`:
- Replace `COURSE_TITLE` with actual title (2 places)
- Replace `ACCENT_*` placeholders with chosen palette values
- Add one `<button class="nav-dot" ...>` per module in `NAV_DOTS`

### Step 6: Write module HTML partials

Each module is a `<section class="module" id="module-N">` partial — no `<html>`, `<head>`, `<body>`, `<style>`, or `<script>` tags.

For simple courses (≤5 modules): write sequentially.
For complex courses (>5 modules): dispatch to parallel subagents using the brief as the spec.

Key rules:
- Every technical term gets a `<span class="term" data-definition="...">` tooltip
- Code snippets are EXACT copies from codebase — never modified
- Keep text blocks ≤3 sentences; screens should be ≥50% visual elements
- Use CSS classes and `data-*` attributes from `references/interactive-elements.md`

### Step 7: Assemble and verify

```bash
cd course && bash build.sh
# Produces index.html

# Open in browser
open index.html
```

Verify manually:
- [ ] Nav dots match module count
- [ ] Each quiz has ≥1 question
- [ ] Each module has ≥1 interactive element (animation, drag-drop, quiz, etc.)
- [ ] Code↔English translations use exact codebase snippets
- [ ] No horizontal scrollbars on code blocks
- [ ] Tooltips not clipped by overflow containers

---

## Regeneration Checklist

When regenerating after codebase changes:

- [ ] Update code snippets in `briefs/00-curriculum.md` with new file:line references
- [ ] Update module HTML partials if architecture changed
- [ ] Verify new modules have nav dot entries in `_base.html`
- [ ] Re-run `build.sh` and verify in browser
- [ ] Check quizzes still have meaningful scenario questions (not just definitions)
- [ ] Ensure actor colors remain consistent across modules
