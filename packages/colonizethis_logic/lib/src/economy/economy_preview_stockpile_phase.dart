/// Economy preview phases for production-panel stockpile projection.
/// Resolver order: Pending build/train costs → Extraction → Riches-to-treasury
/// → Consumption → Production.
/// SPEC/ui/production-panel.md, SPEC/program/order-projections.md.
enum EconomyPreviewStockpilePhase {
  pendingBuildTrainCosts,
  extraction,
  richesToTreasury,
  consumption,
  production,
}
