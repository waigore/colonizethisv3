# UI component specs

**SPEC/ui/components/** — Reusable composite widgets referenced from screen specs. Each file documents layout hierarchy, props, states, and behavior **without** a screen ID.

Authoring rules: [`.cursor/rules/colonizethis-ui-documentation.mdc`](../../../.cursor/rules/colonizethis-ui-documentation.mdc) (§ Component specs). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md).

Create `<kebab-name>.md` before duplicating composite layout in multiple screen specs.

## Index

| Component | File | Consumed by |
|-----------|------|-------------|
| `CtFullScreenDialogueShell` | [`ct-full-screen-dialogue-shell.md`](ct-full-screen-dialogue-shell.md) | `OVL10001` (game-start intro), `OVL30001` (overture), `OVL40001` (call-to-arms), `OVL50001` (pending intervention). |
| `CtGameFeatureScreenShell` | [`ct-game-feature-screen-shell.md`](ct-game-feature-screen-shell.md) | `GAME20001` (production), `GAME30001` (diplomacy), `GAME40001` (technology), `GAME60001` (trade). |
| `CtTransferList` | [`ct-transfer-list.md`](ct-transfer-list.md) | `DLG40001` (transfer to home fleet), Split Fleet dialog, Split Army dialog. |
| `UnitsEntityActionRow` | [`units-entity-action-row.md`](units-entity-action-row.md) | `UNIT10001` (civilian units panel), `UNIT20001` (military units panel), `UNIT30001` (naval units panel). |
| `UnitsPanelShell` | [`units-panel-shell.md`](units-panel-shell.md) | `UNIT10001` (civilian units panel), `UNIT20001` (military units panel), `UNIT30001` (naval units panel). |
