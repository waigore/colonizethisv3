// SPEC/ui/components/dialogue-tristate-decision-row.md + #4018 helpers.
import 'dart:io';

import 'package:colonizethis_app/features/game/widgets/dialogue/dialogue_tristate_decision_row.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/titled_dialogue_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/panels/tree_builders/draft_move_destination_line.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_full_screen_dialogue_shell.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('dialogueTristateAllDecided', () {
    test('positive: all non-null returns true', () {
      expect(dialogueTristateAllDecided(const [true, false, true]), isTrue);
    });

    test('negative: any null returns false', () {
      expect(dialogueTristateAllDecided(const [true, null, false]), isFalse);
      expect(dialogueTristateAllDecided(const <bool?>[]), isTrue);
    });
  });

  group('formatDraftMoveDestinationLine', () {
    test('positive: plain destination', () {
      expect(
        formatDraftMoveDestinationLine('Lisbon'),
        'Moving to: Lisbon',
      );
    });

    test('positive: parenthetical dock suffix', () {
      expect(
        formatDraftMoveDestinationLine('Lisbon', parenthetical: 'dock'),
        'Moving to: Lisbon (dock)',
      );
    });

    test('negative: empty parenthetical ignored', () {
      expect(
        formatDraftMoveDestinationLine('Lisbon', parenthetical: ''),
        'Moving to: Lisbon',
      );
    });
  });

  group('mapCanvasHighlightSlice / mapProvinceDetailHostSlice', () {
    test('highlight slice omits overlayOpen', () {
      const state = MapProvincePanelUiState(
        overlayOpen: true,
        selectedTileKey: 'r|p|0|0',
        secondaryHighlightTileKey: 'r|p|1|0',
        secondaryHighlightTileKeys: {'r|p|2|0'},
      );
      final slice = mapCanvasHighlightSlice(state);
      expect(slice.selectedTileKey, 'r|p|0|0');
      expect(slice.secondaryHighlightTileKey, 'r|p|1|0');
      expect(slice.secondaryHighlightTileKeys, {'r|p|2|0'});
    });

    test('detail host slice omits secondary highlights', () {
      const state = MapProvincePanelUiState(
        overlayOpen: true,
        selectedTileKey: 'r|p|0|0',
        secondaryHighlightTileKey: 'r|p|1|0',
        secondaryHighlightTileKeys: {'r|p|2|0'},
      );
      final slice = mapProvinceDetailHostSlice(state);
      expect(slice.overlayOpen, isTrue);
      expect(slice.selectedTileKey, 'r|p|0|0');
    });

    test('select equality: secondary-only change does not equal prior canvas',
        () {
      const a = MapProvincePanelUiState(
        overlayOpen: true,
        selectedTileKey: 'r|p|0|0',
      );
      const b = MapProvincePanelUiState(
        overlayOpen: true,
        selectedTileKey: 'r|p|0|0',
        secondaryHighlightTileKey: 'r|p|9|9',
      );
      expect(mapCanvasHighlightSlice(a) == mapCanvasHighlightSlice(b), isFalse);
      expect(
        mapProvinceDetailHostSlice(a) == mapProvinceDetailHostSlice(b),
        isTrue,
      );
    });

    test('select equality: overlayOpen-only change does not rebuild canvas slice',
        () {
      const a = MapProvincePanelUiState(
        overlayOpen: true,
        selectedTileKey: 'r|p|0|0',
        secondaryHighlightTileKey: 'r|p|1|0',
      );
      const b = MapProvincePanelUiState(
        overlayOpen: false,
        selectedTileKey: 'r|p|0|0',
        secondaryHighlightTileKey: 'r|p|1|0',
      );
      expect(mapCanvasHighlightSlice(a) == mapCanvasHighlightSlice(b), isTrue);
      expect(
        mapProvinceDetailHostSlice(a) == mapProvinceDetailHostSlice(b),
        isFalse,
      );
    });
  });

  testWidgets('DialogueTristateDecisionRow wires dual toggles', (tester) async {
    bool? decision;
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: DialogueTristateDecisionRow(
            positiveToggleKey: const ValueKey('pos'),
            negativeToggleKey: const ValueKey('neg'),
            positiveLabel: 'Accept',
            negativeLabel: 'Reject',
            decision: decision,
            onDecisionChanged: (v) => decision = v,
          ),
        ),
      ),
    );
    expect(find.byType(CtToggleSwitch), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('pos')));
    await tester.pump();
    expect(decision, isTrue);
  });

  testWidgets('buildTitledDialogueChrome mounts title and brass frame body',
      (tester) async {
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    await tester.pumpWidget(
      buildAppShell(
        child: buildTitledDialogueChrome(
          backdrop: const SizedBox.shrink(),
          title: 'Intro',
          body: const Text('body-line'),
        ),
      ),
    );
    expect(find.byType(CtFullScreenDialogueShell), findsOneWidget);
    expect(find.byType(TitledDialogueChromeTitle), findsOneWidget);
    expect(find.text('Intro'), findsOneWidget);
    expect(find.text('body-line'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Intro'));
    expect(title.style?.color, EditorialMonoclePalette.accent);
  });

  testWidgets(
    'mapProvincePanelProvider.select: secondary highlight rebuilds canvas '
    'subscription but not detail-host subscription',
    (tester) async {
      var canvasBuilds = 0;
      var detailBuilds = 0;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Column(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(
                    mapProvincePanelProvider.select(mapCanvasHighlightSlice),
                  );
                  canvasBuilds++;
                  return const SizedBox.shrink();
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(
                    mapProvincePanelProvider.select(mapProvinceDetailHostSlice),
                  );
                  detailBuilds++;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      final canvasAfterMount = canvasBuilds;
      final detailAfterMount = detailBuilds;

      container
          .read(mapProvincePanelProvider.notifier)
          .setSecondaryHighlight('r|p|3|0');
      await tester.pump();

      expect(canvasBuilds, greaterThan(canvasAfterMount));
      expect(detailBuilds, detailAfterMount);
    },
  );

  group('GameMapAreaStateLogic explicit-import library (#4018, #4117)', () {
    test('positive: state-logic library has no part directives or Api* hops', () {
      final mapStateDir = Directory(
        '${Directory.current.path}/lib/features/game/flame/map_state',
      );
      final names = mapStateDir
          .listSync()
          .whereType<File>()
          .map((f) => p.basename(f.path))
          .toList();
      expect(names, contains('game_map_area_state_logic.dart'));
      expect(names, isNot(contains('game_map_area_state_logic_forwarders.dart')));
      expect(
        names.where((n) => n.contains('forwarders_')).toList(),
        isEmpty,
      );
      final library = File(
        '${mapStateDir.path}/game_map_area_state_logic.dart',
      ).readAsStringSync();
      expect(library.contains('_GameMapAreaStateLogicApi'), isFalse);
      expect(library.contains('GameMapAreaStateLogicShell.'), isTrue);
      expect(library.contains('GameMapAreaStateLogicWorkTargets.'), isTrue);
      expect(library.contains('GameMapAreaStateLogicDraftProjection.'), isTrue);
      expect(library.contains('GameMapAreaStateLogicProvinceActions.'), isTrue);
    });

    test('negative: state-logic library does not declare part directives', () {
      final library = File(
        '${Directory.current.path}/lib/features/game/flame/map_state/'
        'game_map_area_state_logic.dart',
      ).readAsStringSync();
      expect(
        library.contains("part 'game_map_area_state_logic_forwarders_"),
        isFalse,
      );
      expect(
        RegExp(r'^\s*part\s+', multiLine: true).hasMatch(library),
        isFalse,
      );
      expect(
        RegExp(r'^\s*part\s+of\s+', multiLine: true).hasMatch(library),
        isFalse,
      );
    });
  });
}
