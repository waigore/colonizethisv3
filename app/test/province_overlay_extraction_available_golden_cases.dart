// Snapshot fixtures for province overlay extraction goldens (Refs #4002, #4064).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ProvinceImprovableCommodityCount;
import 'package:colonizethis_models/colonizethis_models.dart';

ProvinceExtractionSnapshot partialBracketExtractionSnapshot(String ownerId) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    byCommodity: {
      'grain': const ProvinceExtractionCommodityTotals(
        effective: 1,
        full: 5,
        tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
      ),
      'iron': const ProvinceExtractionCommodityTotals(
        effective: 5,
        full: 5,
        tileKeys: ['oldWorld|p1|1|0'],
      ),
    },
  );
}

const Map<String, ProvinceImprovableCommodityCount>
    sampleExtractionGoldenAvailable = {
  'grain': ProvinceImprovableCommodityCount(
    count: 3,
    tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|2|0'],
  ),
  'timber': ProvinceImprovableCommodityCount(
    count: 2,
    tileKeys: ['oldWorld|p1|0|1'],
  ),
};

ProvinceExtractionSnapshot multiCommodityExtractionSnapshot(String ownerId) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    byCommodity: {
      for (final id in const [
        'grain',
        'meat',
        'wool',
        'timber',
        'iron',
        'copper',
      ])
        id: ProvinceExtractionCommodityTotals(
          effective: 2,
          full: 2,
          tileKeys: ['oldWorld|p1|0|0'],
        ),
    },
  );
}

ProvinceExtractionSnapshot capitalBonusExtractionSnapshot(String ownerId) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    capitalGrainBonus: 2,
    byCommodity: {
      'grain': const ProvinceExtractionCommodityTotals(
        effective: 3,
        full: 7,
        tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
      ),
      'iron': const ProvinceExtractionCommodityTotals(
        effective: 5,
        full: 5,
        tileKeys: ['oldWorld|p1|1|0'],
      ),
    },
  );
}
