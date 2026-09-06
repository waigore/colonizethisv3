// Research and idle-spy exclusions for staged decree review (Refs #4715, UXD).
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
