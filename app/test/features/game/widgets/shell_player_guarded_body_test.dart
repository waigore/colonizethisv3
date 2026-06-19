// Tests for shell_player_guarded_body.dart (Refs #3546 target state #1).
//
// The canonical observe-mode guard replaced the `shellPanelsNotDefined(...) ->
// ObserveModeNotDefinedPanel` branch duplicated across the trade / technology /
// production / diplomacy screen bodies and the military/naval unit-panel sheets.
// These tests pin both branches of the single helper:
//
// - Player chrome defined: returns null so the caller renders its own
//   player-scoped body (and reads `canMutateViaUi` itself).
// - Global observe, no player chrome: returns an ObserveModeNotDefinedPanel
//   titled with the supplied title.

import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/features/game/widgets/shell_player_guarded_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ShellPlayerContext _shell({
  required bool showPlayerChrome,
  bool canMutateViaUi = true,
}) {
  return ShellPlayerContext(
    effectiveHumanPlayerId: showPlayerChrome ? 'P1' : null,
    viewingPlayerId: showPlayerChrome ? 'P1' : null,
    mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
    playerView: null,
    omniscientDetail: false,
    showPlayerChrome: showPlayerChrome,
    canMutateViaUi: canMutateViaUi,
    debugCommandTargetPlayerId: null,
    inObservePhase: !showPlayerChrome,
    observeBannerLabel: null,
    treasuryNotDefined: false,
    cargoNotDefined: false,
  );
}

void main() {
  group('observeNotDefinedSentinel', () {
    test('returns null when the shell has defined player chrome', () {
      final sentinel = observeNotDefinedSentinel(
        _shell(showPlayerChrome: true),
        'Trade',
      );
      expect(sentinel, isNull);
    });

    test('returns an ObserveModeNotDefinedPanel when player chrome is hidden', () {
      final sentinel = observeNotDefinedSentinel(
        _shell(showPlayerChrome: false),
        'Diplomacy',
      );
      expect(sentinel, isA<ObserveModeNotDefinedPanel>());
      expect((sentinel! as ObserveModeNotDefinedPanel).title, 'Diplomacy');
    });

    testWidgets('rendered sentinel shows the supplied title', (tester) async {
      final sentinel = observeNotDefinedSentinel(
        _shell(showPlayerChrome: false),
        'Military Units',
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: sentinel)),
      );

      expect(find.byType(ObserveModeNotDefinedPanel), findsOneWidget);
      expect(find.text('Military Units'), findsOneWidget);
    });
  });
}
