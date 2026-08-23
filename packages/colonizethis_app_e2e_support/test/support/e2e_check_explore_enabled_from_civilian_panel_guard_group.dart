// Extracted from e2e_check_explore_enabled_from_civilian_panel_test.dart
// (#4598 Slice C).
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

import 'expect_panel_texts_harness.dart' as panel_host;

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders _emptyOrders = Orders();

Game _game() => const Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eCivilianPanelSnapshot _civilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

void registerCheckExploreEnabledFromCivilianPanelGuardGroup() {
  group('e2eCheckExploreEnabledFromCivilianPanel — snapshot short-circuit', () {
    testWidgets('snapshot says Explore enabled -> returns true and emits '
        'result=enabled timing event', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'explorer-1': [kWorkTargetExplore],
        },
      );
      await tester.pumpWidget(
        panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
          ListTile(title: Text('Stub')),
        ]),
      );
      final perf = shared.E2ePerfLog('check_explore_pin');
      late bool result;
      final lines = await panel_host.captureDebugPrints(() async {
        result = await e2eCheckExploreEnabledFromCivilianPanel(
          tester,
          perf: perf,
          maxUiResponseWait: const Duration(seconds: 5),
        );
      });
      expect(result, isTrue);
      final timingLines = lines
          .where((line) => line.startsWith('E2E_TIMING|'))
          .toList();
      expect(
        timingLines.any(
          (line) =>
              line.contains('|phase=$kE2eDefaultBundledExploreRetryLoopPhase|'),
        ),
        isTrue,
        reason:
            'A successful return must emit exactly one `E2E_TIMING` '
            'marker keyed on `bundled_explore_retry_loop` — the '
            'phase name AC8 / Bottleneck 5 dashboards key on.',
      );
      expect(
        timingLines.any((line) => line.endsWith('|meta=result=enabled')),
        isTrue,
        reason:
            'The `meta=result=enabled` payload distinguishes successful '
            'Explore detection from the `not_enabled` exhaustion path; '
            'a regression that flipped the boolean encoding would '
            'silently invert AC8 success/fail attribution.',
      );
    });

    testWidgets('snapshot says no Explore enabled -> returns false and emits '
        'result=not_enabled timing event', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
        },
      );
      await tester.pumpWidget(
        panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
          ListTile(title: Text('Stub')),
        ]),
      );
      final perf = shared.E2ePerfLog('check_explore_pin');
      late bool result;
      final lines = await panel_host.captureDebugPrints(() async {
        result = await e2eCheckExploreEnabledFromCivilianPanel(
          tester,
          perf: perf,
        );
      });
      expect(result, isFalse);
      final timingLines = lines
          .where((line) => line.startsWith('E2E_TIMING|'))
          .toList();
      expect(
        timingLines.any((line) => line.endsWith('|meta=result=not_enabled')),
        isTrue,
        reason:
            'A snapshot `false` verdict must still emit a timing '
            'event so dashboards counting retry iterations (every '
            'iteration of the bounded retry window) attribute the '
            'exhaustion path correctly; dropping the marker on '
            '`false` would skew Bottleneck 5 cost attribution.',
      );
    });

    testWidgets(
      'perf parameter is optional — no E2E_TIMING marker emitted when '
      'perf is null',
      (tester) async {
        ctE2eCivilianPanelSnapshot = _civilianSnapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(
          panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
            ListTile(title: Text('Stub')),
          ]),
        );
        late bool result;
        final lines = await panel_host.captureDebugPrints(() async {
          result = await e2eCheckExploreEnabledFromCivilianPanel(tester);
        });
        expect(result, isTrue);
        expect(
          lines.where((line) => line.startsWith('E2E_TIMING|')),
          isEmpty,
          reason:
              'Callers that opt out of perf logging (no shared '
              '`E2ePerfLog`) must not trigger spurious markers; the '
              'helper must guard the `perf?.timing(...)` call with a '
              'null check so unit tests / future stand-alone callers '
              'can use the helper without instantiating a perf log.',
        );
      },
    );
  });

  group(
    'e2eCheckExploreEnabledFromCivilianPanel — phaseTimingLabel override',
    () {
      testWidgets(
        'phaseTimingLabel overrides the default phase= field while keeping '
        'meta=result=...',
        (tester) async {
          ctE2eCivilianPanelSnapshot = _civilianSnapshot(
            availableWorkTargets: const {
              'explorer-1': [kWorkTargetExplore],
            },
          );
          await tester.pumpWidget(
            panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
              ListTile(title: Text('Stub')),
            ]),
          );
          final perf = shared.E2ePerfLog('check_explore_pin');
          final lines = await panel_host.captureDebugPrints(() async {
            await e2eCheckExploreEnabledFromCivilianPanel(
              tester,
              perf: perf,
              phaseTimingLabel: 'pin_custom_phase',
            );
          });
          final timingLines = lines
              .where((line) => line.startsWith('E2E_TIMING|'))
              .toList();
          expect(
            timingLines.any(
              (line) =>
                  line.contains('|phase=pin_custom_phase|') &&
                  line.endsWith('|meta=result=enabled'),
            ),
            isTrue,
            reason:
                'Callers (for example a future develop-phase retry loop '
                'reusing the same composition) must be able to attribute '
                'their timing under a distinct phase label without '
                'forking the helper implementation. A regression that '
                'hard-coded the default would silently merge attribution '
                'across scenarios.',
          );
        },
      );
    },
  );

  group('e2eCheckExploreEnabledFromCivilianPanel — AC1 barrel forwarding', () {
    testWidgets(
      'checkExploreEnabledFromCivilianPanel (barrel alias) returns the '
      'same boolean as the lifted form',
      (tester) async {
        ctE2eCivilianPanelSnapshot = _civilianSnapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(
          panel_host.wrap(kCtE2ECivilianPanelRootKey, const [
            ListTile(title: Text('Stub')),
          ]),
        );
        final result = await checkExploreEnabledFromCivilianPanel(tester);
        expect(
          result,
          isTrue,
          reason:
              'The AC1 barrel wrapper must forward all named arguments '
              'in the documented order and preserve the boolean return '
              'value. A regression that dropped `tester` from the '
              'signature, swapped `perf` with `maxUiResponseWait`, or '
              'fail-opened to `false` would surface here, not in the '
              'slow CI lane.',
        );
      },
    );

    test('checkExploreEnabledFromCivilianPanel is re-exported as a tear-off '
        '(compile-time signature pin)', () {
      final Future<bool> Function(
        WidgetTester, {
        shared.E2ePerfLog? perf,
        Duration maxUiResponseWait,
        String afterSheetPanelsClearPhase,
        String phaseTimingLabel,
      })
      ref = checkExploreEnabledFromCivilianPanel;
      expect(
        ref,
        isNotNull,
        reason:
            'The AC1 barrel must continue to export the helper with '
            'the documented signature. A silent removal from the '
            '`show` clause, an arg-order swap on the wrapper, or a '
            'changed default for `maxUiResponseWait` / '
            '`afterSheetPanelsClearPhase` / `phaseTimingLabel` '
            'would fail this assignment at compile time.',
      );
    });
  });
}
