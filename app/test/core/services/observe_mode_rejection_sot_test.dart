import 'dart:io';

import 'package:colonizethis_app/core/services/observe/observe_mode_session_handler.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Observe-mode mutation rejection SoT (Refs #4450 AC6–AC7).
void main() {
  suppressLogsForTests();

  const snackCopy = 'Observe mode: UI actions are read-only.';

  test(
    'rejectUiMutationIfObserving shows the read-only snack when blocked',
    () {
      final snacks = <ShowSnackBarEvent>[];
      final blocked = rejectUiMutationIfObserving(
        shell: ShellPlayerContext.globalObserve(),
        showSnack: snacks.add,
      );
      expect(blocked, isTrue);
      expect(snacks, hasLength(1));
      expect(snacks.single.message, snackCopy);
    },
  );

  test('rejectUiMutationIfObserving is a no-op when the shell can mutate', () {
    final snacks = <ShowSnackBarEvent>[];
    final blocked = rejectUiMutationIfObserving(
      shell: const ShellPlayerContext(
        effectiveHumanPlayerId: 'gp1',
        viewingPlayerId: 'gp1',
        mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
        playerView: null,
        omniscientDetail: false,
        showPlayerChrome: true,
        canMutateViaUi: true,
        debugCommandTargetPlayerId: null,
        inObservePhase: false,
        observeBannerLabel: null,
        treasuryNotDefined: false,
        cargoNotDefined: false,
      ),
      showSnack: snacks.add,
    );
    expect(blocked, isFalse);
    expect(snacks, isEmpty);
  });

  test('core services declare the observe-blocked snack copy once', () {
    final servicesDir = Directory('lib/core/services');
    expect(servicesDir.existsSync(), isTrue);
    final hits = <String>[];
    for (final entity in servicesDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final contents = entity.readAsStringSync();
      if (contents.contains("'$snackCopy'") ||
          contents.contains('"$snackCopy"')) {
        hits.add(entity.path.replaceAll(r'\', '/'));
      }
    }
    expect(
      hits,
      ['lib/core/services/observe/observe_mode_session_handler.dart'],
      reason: 'Handlers must call rejectUiMutationIfObserving (Refs #4450 AC6)',
    );
  });
}
