#!/usr/bin/env python3
"""Score SPEC/ui screen specs against the 9-section template (issue #2784 rubric)."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SPEC_UI = REPO_ROOT / "SPEC" / "ui"

IN_SCOPE_FILES = [
    "shell-screen.md",
    "main-menu.md",
    "game-screen.md",
    "production-panel.md",
    "diplomacy-panel.md",
    "technology-panel.md",
    "empire-overview.md",
    "province-sea-zone-detail-overlay.md",
    "civilian-units-panel.md",
    "military-units-panel.md",
    "naval-units-panel.md",
    "new-game-leader-selection-dialog.md",
    "move-army-dialog.md",
    "move-fleet-dialog.md",
    "transfer-to-home-fleet-dialog.md",
    "game-start-intro-overlay.md",
    "victory-overlay.md",
    "overture-dialogue-overlay.md",
    "quick-battle-screen.md",
]

H2_PATTERNS = {
    "widget_contract": re.compile(r"^##\s+Widget contract\s*$", re.I | re.M),
    "trigger": re.compile(
        r"^##\s+(Trigger conditions|Triggers|Trigger|Access|Panel placement and opening)\s*$",
        re.I | re.M,
    ),
    "layout": re.compile(
        r"^##\s+(Layout / wireframe|Layout|Wireframe|Wireframe \(conceptual\))\s*$",
        re.I | re.M,
    ),
    "behavior": re.compile(
        r"^##\s+(Behavior|Behaviour|Actions|User actions)\s*$",
        re.I | re.M,
    ),
    "states": re.compile(
        r"^##\s+(States and variants|States|Variants)\s*$",
        re.I | re.M,
    ),
    "components": re.compile(r"^##\s+(Components|Widget catalog)\s*$", re.I | re.M),
    "widgetbook": re.compile(r"^##\s+Widgetbook\s*$", re.I | re.M),
    "acceptance": re.compile(
        r"^##\s+Acceptance criteria.*$",
        re.I | re.M,
    ),
}

H3_INCOMING = re.compile(r"^###\s+Incoming\b", re.I | re.M)
H3_USER_ACTIONS = re.compile(
    r"^###\s+User actions\s*→\s*outcomes\s*$",
    re.I | re.M,
)

HEADER_SCREEN_ID = re.compile(r"\*\*Screen ID:\*\*", re.I)
HEADER_SPEC_UI = re.compile(r"\*\*SPEC/ui\*\*", re.I)
HEADER_WIDGETBOOK = re.compile(r"\*\*Widgetbook:\*\*", re.I)


@dataclass
class Score:
    path: Path
    header_block: bool
    widget_contract: bool
    trigger: bool
    layout: bool
    behavior: bool
    behavior_complete: bool
    states: bool
    components: bool
    widgetbook: bool
    acceptance: bool

    @property
    def section_count(self) -> int:
        return sum(
            [
                self.header_block,
                self.widget_contract,
                self.trigger,
                self.layout,
                self.behavior,
                self.states,
                self.components,
                self.widgetbook,
                self.acceptance,
            ]
        )

    def classify(self) -> str:
        if self.section_count == 9 and self.header_block and self.behavior_complete:
            return "C"
        non_header = self.section_count - (1 if self.header_block else 0)
        if (
            self.section_count <= 4
            or (not self.header_block and non_header <= 6)
        ):
            return "A"
        if 5 <= self.section_count <= 8 and (
            not self.header_block or not self.behavior_complete
        ):
            return "B"
        if self.section_count >= 5:
            return "B"
        return "A"


def score_file(path: Path) -> Score:
    text = path.read_text(encoding="utf-8")
    # Header block: first ~30 lines after title
    head = text.split("\n", 40)[:40]
    head_blob = "\n".join(head)
    header_block = bool(
        HEADER_SCREEN_ID.search(head_blob)
        and HEADER_SPEC_UI.search(head_blob)
        and HEADER_WIDGETBOOK.search(head_blob)
    )
    behavior = bool(H2_PATTERNS["behavior"].search(text))
    behavior_complete = behavior and bool(H3_INCOMING.search(text)) and bool(
        H3_USER_ACTIONS.search(text)
    )
    return Score(
        path=path,
        header_block=header_block,
        widget_contract=bool(H2_PATTERNS["widget_contract"].search(text)),
        trigger=bool(H2_PATTERNS["trigger"].search(text)),
        layout=bool(H2_PATTERNS["layout"].search(text)),
        behavior=behavior,
        behavior_complete=behavior_complete,
        states=bool(H2_PATTERNS["states"].search(text)),
        components=bool(H2_PATTERNS["components"].search(text)),
        widgetbook=bool(H2_PATTERNS["widgetbook"].search(text)),
        acceptance=bool(H2_PATTERNS["acceptance"].search(text)),
    )


def format_row(s: Score) -> str:
    flags = "".join(
        [
            "H" if s.header_block else "-",
            "W" if s.widget_contract else "-",
            "T" if s.trigger else "-",
            "L" if s.layout else "-",
            "B" if s.behavior else "-",
            "b" if s.behavior_complete else "-",
            "S" if s.states else "-",
            "C" if s.components else "-",
            "K" if s.widgetbook else "-",
            "A" if s.acceptance else "-",
        ]
    )
    return (
        f"{s.path.name:45} {s.section_count}/9 {flags}  Class {s.classify()}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--file",
        action="append",
        help="Single spec filename under SPEC/ui/ (default: all 20 in-scope)",
    )
    args = parser.parse_args()
    names = args.file or IN_SCOPE_FILES
    scores: list[Score] = []
    missing: list[str] = []
    for name in names:
        path = SPEC_UI / name
        if not path.is_file():
            missing.append(name)
            continue
        scores.append(score_file(path))
    if missing:
        print("Missing files:", ", ".join(missing), file=sys.stderr)
    print("Legend: H=header W=widget_contract T=trigger L=layout B=behavior")
    print("        b=behavior complete S=states C=components K=widgetbook A=AC")
    print()
    for s in scores:
        print(format_row(s))
    counts = {"A": 0, "B": 0, "C": 0}
    for s in scores:
        counts[s.classify()] += 1
    print()
    print(
        f"Summary: {len(scores)} files — "
        f"Class A={counts['A']}, Class B={counts['B']}, Class C={counts['C']}"
    )
    compliant = sum(1 for s in scores if s.classify() == "C")
    print(f"Compliant (Class C): {compliant}/{len(scores)}")
    return 0 if compliant == len(scores) and not missing else 1


if __name__ == "__main__":
    sys.exit(main())
