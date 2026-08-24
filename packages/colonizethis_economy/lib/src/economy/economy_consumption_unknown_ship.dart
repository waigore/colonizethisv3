/// Thrown when consumption sees a ship type id not in [ShipEconomyCatalog].
/// SPEC/game/workers-and-population.md (invalid fleet data).
class ConsumptionUnknownShipTypeException implements Exception {
  ConsumptionUnknownShipTypeException(this.shipTypeId);
  final String shipTypeId;

  @override
  String toString() =>
      'ConsumptionUnknownShipTypeException: unknown ship type $shipTypeId';
}
