/// Economy preview phases for production-panel stockpile projection.
/// Resolver order:
/// Pending build costs → Extraction → Riches-to-treasury → Consumption → Production.
/// SPEC/ui/production-panel.md, SPEC/program/order-projections.md.
enum EconomyPreviewStockpilePhase {
  pendingBuildCosts,
  extraction,
  richesToTreasury,
  consumption,
  production,
}
