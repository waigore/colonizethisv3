import 'package:colonizethis_app/features/game/widgets/diplomacy_order_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('diplomacyActionLabel', () {
    test('formats non-parameter actions', () {
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ),
        'Declare War',
      );
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ),
        'Offer Peace',
      );
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.alliance,
            targetFactionId: 'gp2',
          ),
        ),
        'Alliance',
      );
    });

    test('formats overture and amount actions', () {
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'mn1',
            overtureStage: OvertureStage.embassy,
          ),
        ),
        'Embassy',
      );
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.grantAid,
            targetFactionId: 'mn1',
            amount: 1000,
          ),
        ),
        'Grant Aid',
      );
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.setSubsidy,
            targetFactionId: 'mn1',
            amount: 10,
          ),
        ),
        'Set Subsidy (10%)',
      );
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.establishFtp,
            targetFactionId: 'gp2',
          ),
        ),
        'Establish FTP',
      );
    });

    // Refs #3753 R11 (Break Alliance) / R14 + S14 (Boycott / Revoke Boycott):
    // the expanded-diplomacy action buttons must surface the labels pinned by
    // SPEC/ui/diplomacy-panel.md § Per-faction row (Great Power row controls:
    // ..., Boycott, Revoke Boycott) and the unified break-alliance order.
    test('formats expanded-diplomacy actions (boycott, break alliance)', () {
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.breakAlliance,
            targetFactionId: 'gp2',
          ),
        ),
        'Break Alliance',
      );
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.boycott,
            targetFactionId: 'gp2',
          ),
        ),
        'Boycott',
      );
      expect(
        diplomacyActionLabel(
          const DiplomaticOrder(
            type: DiplomaticOrderType.revokeBoycott,
            targetFactionId: 'gp2',
          ),
        ),
        'Revoke Boycott',
      );
    });
  });

  group('DiplomacyOrderMutations', () {
    test(
      'appendDiplomaticOrderForPlayer appends and preserves other players',
      () {
        const existing = DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'gp2',
        );
        const appended = DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp3',
        );
        const otherPlayerOrder = DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp1',
        );
        final start = Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': const [existing],
            'gp2': const [otherPlayerOrder],
          },
        );

        final updated = start.appendDiplomaticOrderForPlayer('gp1', appended);

        expect(updated.diplomaticOrdersByPlayerId['gp1'], const [
          existing,
          appended,
        ]);
        expect(updated.diplomaticOrdersByPlayerId['gp2'], const [
          otherPlayerOrder,
        ]);
        expect(start.diplomaticOrdersByPlayerId['gp1'], const [existing]);
      },
    );

    test(
      'removeDiplomaticOrderForPlayer removes only matching type and target',
      () {
        const keep = DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        );
        const remove = DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'gp3',
        );
        const otherTarget = DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'gp4',
        );
        final start = Orders(
          diplomaticOrdersByPlayerId: {
            'gp1': const [keep, remove, otherTarget],
          },
        );

        final updated = start.removeDiplomaticOrderForPlayer(
          'gp1',
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'gp3',
        );

        expect(updated.diplomaticOrdersByPlayerId['gp1'], const [
          keep,
          otherTarget,
        ]);
        expect(start.diplomaticOrdersByPlayerId['gp1'], const [
          keep,
          remove,
          otherTarget,
        ]);
      },
    );
  });
}
