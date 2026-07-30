#!/usr/bin/env python3
"""Transform authoring manual chapters into a self-contained player export.

Refs #4199 WS2. Authoring source: docs/manual/** (except STYLE_GUIDE.md).
Output: docs/manual/player-export/** by default.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_AUTHOR_DIR = ROOT / "docs" / "manual"
DEFAULT_OUTPUT_DIR = DEFAULT_AUTHOR_DIR / "player-export"
DEFAULT_REGISTRY = ROOT / "SPEC" / "ui" / "screen-registry.md"

SECTIONS_TO_DROP = {
    "Sources",
    "Related process artifacts",
    "Chapter status",
    "Coverage map (authoring)",
}

ACCEPTANCE_PREFIX = "Acceptance criteria"

SCREEN_ID_PATTERN = re.compile(r"\b[A-Z]{3,4}\d{5}[a-z]?\b")

ORDER_TYPE_REPLACEMENTS: dict[str, str] = {
    "MoveOrder": "civilian move decree",
    "ArmyMoveOrder": "army move decree",
    "WorkOrder": "civilian work decree",
    "BuildUnitOrder": "build decree",
    "RecruitWorkerOrder": "recruit or train worker decree",
    "ResearchOrder": "research decree",
    "NavalMoveOrder": "fleet move decree",
    "NavalMissionOrder": "fleet mission decree",
    "TradeOrder": "trade decree",
    "DiplomaticOrder": "diplomatic decree",
}

ENGINEER_IDENTIFIER_REPLACEMENTS: dict[str, str] = {
    "ownerId": "ownership",
}

FORBIDDEN_PATTERNS = [
    re.compile(r"SPEC/"),
    re.compile(r"app/lib"),
    re.compile(r"packages/"),
    SCREEN_ID_PATTERN,
    re.compile(
        r"\b("
        + "|".join(ORDER_TYPE_REPLACEMENTS.keys())
        + r")\b"
    ),
]

PLAYER_INDEX = """# ColonizeThis — Player Handbook

Welcome, my liege. This handbook is your national adviser: it immerses you in the age of discovery, guides you patiently toward imperial glory, and catalogs every decree you may issue in play.

## How to use this handbook

1. Start with **A Young Monarch's Primer** for the premise, victory at a glance, and the game screen.
2. Follow chapters in order for a campaign-shaped tour, or jump via the table of contents to a system you need.
3. Use the **Appendix: The Royal Decrees** as a quick-reference for every decree and immediate action.
4. Surfaces are named by their visible titles in the game (for example **Production**, **Diplomacy**, **Next turn**).

## Tone

Body prose is clear modern English for an experienced turn-based strategy player. The framing is a **vizier advising a young monarch**: patient, empathetic, encouraging. Archaic 16th–17th century flourishes appear only in exhortation, warning, or instruction **callouts**.

## Table of contents

| # | Chapter | File |
|---|---------|------|
| 1 | A Young Monarch's Primer | [`01-primer.md`](01-primer.md) |
| 2 | Founding Your Reign | [`02-founding-your-reign.md`](02-founding-your-reign.md) |
| 3 | The Lay of the Land | [`03-the-lay-of-the-land.md`](03-the-lay-of-the-land.md) |
| 4 | Charting the Unknown | [`04-charting-the-unknown.md`](04-charting-the-unknown.md) |
| 5 | People and Prosperity | [`05-people-and-prosperity.md`](05-people-and-prosperity.md) |
| 6 | Bounty of the Earth | [`06-bounty-of-the-earth.md`](06-bounty-of-the-earth.md) |
| 7 | The Engines of Industry | [`07-engines-of-industry.md`](07-engines-of-industry.md) |
| 8 | Commerce and the World Market | [`08-commerce-and-the-world-market.md`](08-commerce-and-the-world-market.md) |
| 9 | The Pursuit of Knowledge | [`09-pursuit-of-knowledge.md`](09-pursuit-of-knowledge.md) |
| 10 | Diplomacy and Courtly Affairs | [`10-diplomacy.md`](10-diplomacy.md) |
| 11 | Raising the Banners | [`11-raising-the-banners.md`](11-raising-the-banners.md) |
| 12 | The Art of War | [`12-art-of-war.md`](12-art-of-war.md) |
| 13 | Mastery of the Seas | [`13-mastery-of-the-seas.md`](13-mastery-of-the-seas.md) |
| 14 | The Passage of Turns | [`14-passage-of-turns.md`](14-passage-of-turns.md) |
| 15 | The Road to Victory | [`15-road-to-victory.md`](15-road-to-victory.md) |
| 16 | Appendix: The Royal Decrees | [`16-appendix-actions.md`](16-appendix-actions.md) |
"""


def parse_screen_registry(registry_path: Path) -> dict[str, str]:
    """Map screen IDs to player-visible titles from screen-registry.md."""
    titles: dict[str, str] = {}
    row_pattern = re.compile(
        r"^\|\s*`([A-Z]{3,4}\d{5}[a-z]?)`\s*\|\s*([^|]+?)\s*\|",
        re.MULTILINE,
    )
    text = registry_path.read_text(encoding="utf-8")
    for match in row_pattern.finditer(text):
        screen_id, title = match.group(1), match.group(2).strip()
        titles[screen_id] = title
    return titles


def strip_authoring_sections(content: str) -> str:
    """Remove Sources, acceptance criteria, and authoring-only sections."""
    lines = content.splitlines(keepends=True)
    kept: list[str] = []
    skipping = False

    for line in lines:
        if line.startswith("## "):
            title = line[3:].strip()
            skipping = (
                title in SECTIONS_TO_DROP
                or title.startswith(ACCEPTANCE_PREFIX)
            )
            if not skipping:
                kept.append(line)
            continue
        if not skipping:
            kept.append(line)

    return "".join(kept).rstrip() + "\n"


def remove_spec_references(content: str) -> str:
    """Drop inline SPEC citations and engineer-only path mentions."""
    content = re.sub(r"\([^)]*SPEC/[^)]*\)", "", content)
    content = re.sub(r"`SPEC/[^`]+`", "", content)
    content = re.sub(r"\bSPEC/[A-Za-z0-9_./-]+", "", content)
    content = re.sub(r"`STYLE_GUIDE\.md`", "", content)
    content = re.sub(r"`colonizethis-game-manual\.mdc`", "", content)
    content = re.sub(r"\.cursor/rules/[^\s`]+", "", content)
    content = re.sub(r"\.cursor/skills/[^\s`]+", "", content)
    return content


def remove_draft_markers(content: str) -> str:
    """Remove **[DRAFT]** `SCREENID` markers, keeping any following title."""
    content = re.sub(
        r"\*\*\[DRAFT\]\*\*\s*`[A-Z]{3,4}\d{5}[a-z]?`\s*",
        "",
        content,
    )
    return content


def replace_screen_ids(content: str, titles: dict[str, str]) -> str:
    """Replace engineer screen IDs with player-visible surface names."""
    for screen_id, title in sorted(titles.items(), key=lambda item: len(item[0]), reverse=True):
        bold_title = f"**{title}**"

        # Authoring pattern: **`SCREENID` short label** (bold wraps backticked id + label).
        content = re.sub(
            rf"\*\*`{re.escape(screen_id)}`\s+([^*]+)\*\*",
            bold_title,
            content,
        )
        content = re.sub(
            rf"`{re.escape(screen_id)}`\s*\*\*([^*]+)\*\*",
            bold_title,
            content,
        )
        content = re.sub(
            rf"`{re.escape(screen_id)}`\s+{re.escape(title)}",
            bold_title,
            content,
            flags=re.IGNORECASE,
        )
        content = re.sub(rf"`{re.escape(screen_id)}`", bold_title, content)
        content = re.sub(
            rf"\b{re.escape(screen_id)}\b\s*\*\*([^*]+)\*\*",
            bold_title,
            content,
        )
        content = re.sub(rf"\b{re.escape(screen_id)}\b", bold_title, content)

    return content


def replace_engineer_identifiers(content: str) -> str:
    for engineer_id, player_label in ENGINEER_IDENTIFIER_REPLACEMENTS.items():
        content = content.replace(f"`{engineer_id}`", player_label)
        content = re.sub(rf"\b{re.escape(engineer_id)}\b", player_label, content)
    return content


def replace_order_types(content: str) -> str:
    """Remove internal order class names; keep player-facing decree language."""
    for order_type, player_label in ORDER_TYPE_REPLACEMENTS.items():
        content = re.sub(
            rf"\s*\(`{re.escape(order_type)}`\)",
            "",
            content,
        )
        content = re.sub(
            rf"`{re.escape(order_type)}`",
            player_label,
            content,
        )
        content = re.sub(rf"\b{re.escape(order_type)}\b", player_label, content)
    return content


def normalize_whitespace(content: str) -> str:
    """Tidy spacing after removals."""
    content = re.sub(r"  +", " ", content)
    content = re.sub(r" +\n", "\n", content)
    content = re.sub(r"\(\s*\)", "", content)
    content = re.sub(r"\n{3,}", "\n\n", content)
    return content.rstrip() + "\n"


def transform_chapter(content: str, titles: dict[str, str]) -> str:
    content = strip_authoring_sections(content)
    content = remove_spec_references(content)
    content = remove_draft_markers(content)
    content = replace_screen_ids(content, titles)
    content = replace_order_types(content)
    content = replace_engineer_identifiers(content)
    return normalize_whitespace(content)


def list_chapter_files(author_dir: Path) -> list[Path]:
    return sorted(author_dir.glob("[0-9][0-9]-*.md"))


def export_manual(
    author_dir: Path,
    output_dir: Path,
    registry_path: Path,
) -> list[Path]:
    titles = parse_screen_registry(registry_path)
    output_dir.mkdir(parents=True, exist_ok=True)

    written: list[Path] = []
    for chapter_path in list_chapter_files(author_dir):
        transformed = transform_chapter(chapter_path.read_text(encoding="utf-8"), titles)
        out_path = output_dir / chapter_path.name
        out_path.write_text(transformed, encoding="utf-8")
        written.append(out_path)

    index_path = output_dir / "index.md"
    index_path.write_text(PLAYER_INDEX, encoding="utf-8")
    written.append(index_path)
    return written


def scan_forbidden(content: str) -> list[str]:
    violations: list[str] = []
    for pattern in FORBIDDEN_PATTERNS:
        for match in pattern.finditer(content):
            violations.append(match.group(0))
    return violations


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Export self-contained player handbook from docs/manual authoring chapters.",
    )
    parser.add_argument(
        "--author-dir",
        type=Path,
        default=DEFAULT_AUTHOR_DIR,
        help="Authoring manual directory (default: docs/manual)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Player export output directory (default: docs/manual/player-export)",
    )
    parser.add_argument(
        "--registry",
        type=Path,
        default=DEFAULT_REGISTRY,
        help="Screen registry markdown path",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate existing export for forbidden engineer identifiers",
    )
    args = parser.parse_args(argv)

    if args.check:
        violations: list[str] = []
        for path in sorted(args.output_dir.rglob("*.md")):
            violations.extend(scan_forbidden(path.read_text(encoding="utf-8")))
        if violations:
            print("Forbidden identifiers found in export:", file=sys.stderr)
            for item in sorted(set(violations)):
                print(f"  - {item}", file=sys.stderr)
            return 1
        print(f"Export check passed: {args.output_dir}")
        return 0

    written = export_manual(args.author_dir, args.output_dir, args.registry)
    violations: list[str] = []
    for path in written:
        violations.extend(scan_forbidden(path.read_text(encoding="utf-8")))
    if violations:
        print("Export produced forbidden identifiers:", file=sys.stderr)
        for item in sorted(set(violations)):
            print(f"  - {item}", file=sys.stderr)
        return 1

    print(f"Exported {len(written)} files to {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
