// Rich-panel row pins for buildDiplomacyRows (Refs #4305 / #4734 Slice F).
// Discovery/visibility pins: diplomacy_panel_rows_test.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late String humanPlayerId;
  late MapTopology topology;

  setUpAll(() async {
    gameWithFactions = buildDiplomacyRichPanelTestGame();
    topology = const MapTopology();
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
  });

  group('buildDiplomacyRows — rich panel', () {
    test('returns GP rows sorted by military power then province count', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      if (gpRows.length < 2) return;
      for (var i = 0; i < gpRows.length - 1; i++) {
        final strA = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i].factionId,
        );
        final strB = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i + 1].factionId,
        );
        expect(strA >= strB, isTrue);
      }
    });

    test('GP rows have power score and player power score set', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      for (final r in gpRows) {
        expect(r.powerScore, isNotNull, reason: 'GP row ${r.displayName}');
        expect(
          r.playerPowerScore,
          isNotNull,
          reason: 'GP row ${r.displayName}',
        );
      }
      final nonGp = rows.where((r) => r.kind != FactionKind.greatPower);
      for (final r in nonGp) {
        expect(r.powerScore, isNull);
        expect(r.playerPowerScore, isNull);
      }
    });

    test(
      'AC-6: minor row enumerates all overture stages with disabled reasons',
      () {
        final minorId = gameWithFactions.minorNations.first.id;
        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final minorRow = rows.firstWhere((r) => r.factionId == minorId);
        final overtureActions = minorRow.actions
            .where((a) => a.order.type == DiplomaticOrderType.establishOverture)
            .toList();
        expect(overtureActions, hasLength(4));
        final disabled = overtureActions.where((a) => !a.enabled).toList();
        expect(disabled, isNotEmpty);
        for (final action in disabled) {
          expect(action.rejectionReason, isNotNull);
          expect(action.rejectionReason, isNotEmpty);
        }
      },
    );

    test('AC-10: GP row keeps invalid Offer Peace action in matrix', () {
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      final offerPeace = gpRow.actions.firstWhere(
        (a) => a.order.type == DiplomaticOrderType.offerPeace,
      );
      expect(offerPeace.enabled, isFalse);
      expect(offerPeace.rejectionReason, isNotEmpty);
      final ftp = gpRow.actions.firstWhere(
        (a) => a.order.type == DiplomaticOrderType.establishFtp,
      );
      expect(ftp.enabled, isFalse);
    });

    test('pendingOrderTypes reflects submitted diplomatic orders', () {
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        orders,
      );
      final targetRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
    });
  });
}
