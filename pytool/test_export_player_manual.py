"""Tests for player manual export (Refs #4199 WS2)."""

from __future__ import annotations

from pathlib import Path

from export_player_manual import (
    export_manual,
    parse_screen_registry,
    scan_forbidden,
    transform_chapter,
)

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "SPEC" / "ui" / "screen-registry.md"


def test_parse_screen_registry_includes_game_screen() -> None:
    titles = parse_screen_registry(REGISTRY)
    assert titles["GAME10001"] == "Game screen"
    assert titles["DLG60001"] == "Next turn confirmation"


def test_transform_chapter_strips_sources_and_acceptance() -> None:
    source = """# Example

## Purpose

Player text.

## Acceptance criteria for this chapter

- [ ] internal checklist

## Sources

- `SPEC/game/foo.md`
"""
    titles = {"GAME10001": "Game screen"}
    result = transform_chapter(source, titles)
    assert "## Sources" not in result
    assert "Acceptance criteria" not in result
    assert "Player text." in result


def test_transform_chapter_replaces_screen_ids_and_order_types() -> None:
    source = """# Example

## How it is done

Open `GAME20001` **Production screen** and issue a `WorkOrder`.
"""
    titles = {"GAME20001": "Production screen"}
    result = transform_chapter(source, titles)
    assert "GAME20001" not in result
    assert "**Production screen**" in result
    assert "WorkOrder" not in result
    assert "civilian work decree" in result


def test_transform_chapter_replaces_bold_wrapped_screen_id() -> None:
    """Authoring **`SCREENID` label** must not leave duplicate bold fragments."""
    source = """# Example

## How it is done

**`GAME80001` Development** lists improvable tiles.
"""
    titles = {"GAME80001": "Development screen"}
    result = transform_chapter(source, titles)
    assert "GAME80001" not in result
    assert result.count("**Development screen**") == 1
    assert "****" not in result


def test_transform_chapter_removes_spec_parenthetical() -> None:
    source = """# Example

## The other courts

Rivals plan alike (`SPEC/ai/growth-stage-planner.md`).
"""
    result = transform_chapter(source, {})
    assert "SPEC/" not in result
    assert "SPEC/" not in result
    assert "Rivals plan alike" in result


def test_export_manual_writes_player_export_tree(tmp_path: Path) -> None:
    author = tmp_path / "manual"
    author.mkdir()
    (author / "01-primer.md").write_text(
        """# Primer

## Purpose

Visit `GAME10001` **Game screen**.

## Sources

- `SPEC/ui/game-screen.md`
""",
        encoding="utf-8",
    )
    output = tmp_path / "export"
    registry = tmp_path / "registry.md"
    registry.write_text(
        "| ID | Title | Spec | Implementation | Widgetbook | Status |\n"
        "|----|-------|------|----------------|------------|--------|\n"
        "| `GAME10001` | Game screen | | | | active |\n",
        encoding="utf-8",
    )

    written = export_manual(author, output, registry)
    assert (output / "index.md").exists()
    assert len(written) == 2

    export_text = (output / "01-primer.md").read_text(encoding="utf-8")
    assert "GAME10001" not in export_text
    assert scan_forbidden(export_text) == []


def test_live_export_has_no_forbidden_identifiers() -> None:
    author = ROOT / "docs" / "manual"
    if not author.exists():
        return
    output = ROOT / "tmp" / "player-export-test"
    export_manual(author, output, REGISTRY)
    violations: list[str] = []
    for path in output.rglob("*.md"):
        violations.extend(scan_forbidden(path.read_text(encoding="utf-8")))
    assert violations == []
