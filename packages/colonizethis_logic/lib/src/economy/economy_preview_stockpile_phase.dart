/// Economy preview phases for production-panel stockpile projection.
/// Resolver order: Extraction → Riches-to-treasury → Consumption → Production.
/// SPEC/ui/production-panel.md, SPEC/program/order-projections.md.
enum EconomyPreviewStockpilePhase {
  extraction,
  richesToTreasury,
  consumption,
  production,
}
