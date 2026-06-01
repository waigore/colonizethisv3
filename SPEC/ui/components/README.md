# UI component specs

**SPEC/ui/components/** — Reusable composite widgets referenced from screen specs. Each file documents layout hierarchy, props, states, and behavior **without** a screen ID.

Authoring rules: [`.cursor/rules/colonizethis-ui-documentation.mdc`](../../../.cursor/rules/colonizethis-ui-documentation.mdc) (§ Component specs). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md).

Create `<kebab-name>.md` before duplicating composite layout in multiple screen specs.

## Index

| Component | File | Consumed by |
|-----------|------|-------------|
| `CtFullScreenDialogueShell` | [`ct-full-screen-dialogue-shell.md`](ct-full-screen-dialogue-shell.md) | `OVL10001` (game-start intro), `OVL30001` (overture), `OVL40001` (call-to-arms), `OVL50001` (pending intervention). |
