import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/full_ai_civilian_work_ow_feedstock_prospect_suggestion_fixtures.dart';

// Refs #2847 § H8-extraction Old World mineral feedstock prospect localization
// (suggestion-generation slice).
void main() {
  group('suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile'
      ' (Refs #2847 H8-extraction prospect suggestion-generation gate)', () {
    bool evaluate(Game game) {
      final topology = prospectSuggestionTopology(game);
      final view = buildPlayerView(game, topology, prospectSuggestionPlayerId);
      return suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
        game,
        topology,
        view,
        prospectSuggestionPlayerId,
        {'iron'},
        null,
      );
    }

    test('true when the suggestion pass emits the co-located iron prospect '
        '(generated + validator-accepted → residual is selection ranking)', () {
      expect(evaluate(prospectSuggestionFeedstockGame()), isTrue);
    });

    test('false when the iron tile is not visible — the pass emits no '
        'prospect (residual inside generation, not selection ranking)', () {
      final game = prospectSuggestionFeedstockGame(tileVisible: false);
      expect(
        ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
          game,
          prospectSuggestionPlayerId,
          {'iron'},
          null,
        ),
        isTrue,
      );
      expect(evaluate(game), isFalse);
    });

    test('false when the co-located Explorer is busy (currentWork set)', () {
      final game = prospectSuggestionFeedstockGame(
        explorerWork: const CurrentWork(
          workTarget: kWorkTargetExplore,
          tileKey: 'newWorld|n0|0|0',
          totalTurns: 5,
          remainingTurns: 3,
        ),
      );
      expect(evaluate(game), isFalse);
    });

    test('false when the idle Explorer is in a different province', () {
      expect(
        evaluate(
          prospectSuggestionFeedstockGame(
            explorerProvinceId: prospectSuggestionOtherProvinceId,
          ),
        ),
        isFalse,
      );
    });

    test('false when the iron tile is already prospected', () {
      expect(
        evaluate(prospectSuggestionFeedstockGame(alreadyProspected: true)),
        isFalse,
      );
    });

    test('false for an empty feedstock set (negative control)', () {
      final game = prospectSuggestionFeedstockGame();
      final topology = prospectSuggestionTopology(game);
      final view = buildPlayerView(game, topology, prospectSuggestionPlayerId);
      expect(
        suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
          game,
          topology,
          view,
          prospectSuggestionPlayerId,
          const <String>{},
          null,
        ),
        isFalse,
      );
    });

    test('deterministic across repeated evaluation', () {
      final game = prospectSuggestionFeedstockGame();
      expect(evaluate(game), evaluate(game));
      expect(evaluate(game), isTrue);
    });
  });
}
