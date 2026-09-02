// SPEC/ui/components/staged-decree-review.md — builder grouping and UXD exclusions.

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_builder.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

const _human = kPanelTestHumanPlayerId;
final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  suppressLogsForTests();

  test('empty human draft yields no staged families', () {
    final review = buildStagedDecreeReview(
      orders: const Orders(),
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(review.isEmpty, isTrue);
  });

  test('one work order becomes civilian work family in player language', () {
    final game = buildPanelTestGame(
      oldWorldProvinces: const [
        Province(
          id: 'oldWorld|p1',
          regionId: kOldWorldRegionId,
          displayName: 'Alpha',
        ),
      ],
      oldWorldUnits: [
        Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: _human,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
        ),
      ],
    );
    final review = buildStagedDecreeReview(
      orders: const Orders(
        workOrdersByPlayerId: {
          _human: [
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      ),
      humanPlayerId: _human,
      l10n: _l10n,
      game: game,
    );
    expect(review.families, hasLength(1));
    expect(review.families.single.family, StagedDecreeFamily.civilianWork);
    expect(review.families.single.familyLabel, 'Civilian work');
    expect(review.families.single.count, 1);
    expect(review.families.single.rows, isEmpty);
    final expanded = expandStagedDecreeReview(
      compact: review,
      orders: const Orders(
        workOrdersByPlayerId: {
          _human: [
            WorkOrder(
              unitId: 'e1',
              target: kWorkTargetExplore,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      ),
      humanPlayerId: _human,
      l10n: _l10n,
      game: game,
    );
    expect(
      expanded.families.single.rows.single.label,
      contains(kUnitTypeExplorer),
    );
    expect(
      expanded.families.single.rows.single.label,
      isNot(contains('WorkOrder')),
    );
  });

  test('multi-family draft names only families with count > 0', () {
    final review = buildStagedDecreeReview(
      orders: Orders(
        armyMoveOrdersByPlayerId: const {
          _human: [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p1'),
          ],
        },
        tradeOrdersByPlayerId: {
          _human: [
            TradeOrder(
              commodityId: CommodityCatalog.grain.id,
              type: TradeOrderType.bid,
              quantity: 10,
              priority: 1,
            ),
          ],
        },
      ),
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(review.families.map((g) => g.family), [
      StagedDecreeFamily.armyMoves,
      StagedDecreeFamily.trade,
    ]);
    expect(review.families.map((g) => g.count), [1, 1]);
    expect(review.families.every((g) => g.rows.isEmpty), isTrue);
  });

  test('compact review expands row labels on demand (Refs #4715)', () {
    final orders = Orders(
      armyMoveOrdersByPlayerId: const {
        _human: [
          ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p1'),
        ],
      },
      tradeOrdersByPlayerId: {
        _human: [
          TradeOrder(
            commodityId: CommodityCatalog.grain.id,
            type: TradeOrderType.bid,
            quantity: 10,
            priority: 1,
          ),
        ],
      },
    );
    final compact = buildStagedDecreeReview(
      orders: orders,
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(compact.families.every((g) => g.rows.isEmpty), isTrue);
    final expanded = expandStagedDecreeReview(
      compact: compact,
      orders: orders,
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(expanded.families.every((g) => g.rowsExpanded), isTrue);
    expect(expanded.families.singleWhere(
      (g) => g.family == StagedDecreeFamily.trade,
    ).rows.single.label, contains('Grain'));
  });

  test('empty and unfunded research slots are omitted (UXD-001)', () {
    final review = buildStagedDecreeReview(
      orders: const Orders(
        researchOrdersByPlayerId: {
          _human: [
            ResearchOrder(
              slotIndex: 0,
              techId: '',
              funding: ResearchFundingLevel.none,
            ),
            ResearchOrder(
              slotIndex: 1,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.none,
            ),
          ],
        },
      ),
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(review.isEmpty, isTrue);
  });

  test('funded research assignment is listed without empty-seat nag', () {
    final review = buildStagedDecreeReview(
      orders: const Orders(
        researchOrdersByPlayerId: {
          _human: [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.high,
            ),
            ResearchOrder(
              slotIndex: 1,
              techId: '',
              funding: ResearchFundingLevel.none,
            ),
          ],
        },
      ),
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(review.families, hasLength(1));
    expect(review.families.single.family, StagedDecreeFamily.research);
    expect(review.families.single.count, 1);
    expect(review.families.single.rows, isEmpty);
    final expanded = expandStagedDecreeReview(
      compact: review,
      orders: const Orders(
        researchOrdersByPlayerId: {
          _human: [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdCropRotation,
              funding: ResearchFundingLevel.high,
            ),
            ResearchOrder(
              slotIndex: 1,
              techId: '',
              funding: ResearchFundingLevel.none,
            ),
          ],
        },
      ),
      humanPlayerId: _human,
      l10n: _l10n,
    );
    expect(expanded.families.single.rows.single.label, contains('Crop Rotation'));
  });

  test('idle Spies are not synthesized as staged rows (UXD-002)', () {
    final game = buildPanelTestGame(
      oldWorldUnits: [
        Unit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: _human,
          locationProvinceId: 'oldWorld|p1',
          tileKey: 'oldWorld|p1|0|0',
        ),
      ],
    );
    final review = buildStagedDecreeReview(
      orders: const Orders(),
      humanPlayerId: _human,
      l10n: _l10n,
      game: game,
    );
    expect(review.isEmpty, isTrue);
  });
}
