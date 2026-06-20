// Widget test pin for the `Diplomacy Panel` → `No factions discovered
// (empty state)` Widgetbook use case added by Refs #2863 S7.
//
// Pins two SPEC contracts from `SPEC/ui/diplomacy-panel.md`
// § Widgetbook (empty-state story) and § Acceptance criteria
// ("Empty-state Widgetbook story renders no-factions copy"):
//
//  1. The use case is wired into the public `diplomacyPanelDirectories`
//     getter under the canonical folder + name (so renaming or removing
//     it surfaces here in CI before reviewers lose the empty-state
//     story for the diplomacy surface).
//  2. The builder mounts without exceptions under the editorial-monocle
//     theme, surfaces the three always-visible section headings
//     (Great Powers / Minor Nations / Tribes) and the
//     `diplomacy_panel_noTribes` copy ("No tribes contacted yet.")
//     beneath the Tribes heading, and renders no faction-row bodies
//     (the fixture `Game` has no discovered factions). Refs #3341.

import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';

/// Pre-warm the brass nine-patch into Flame's image cache so the mode
/// bar button at the bottom of the empty-state panel lays out at its
/// declared height (mirrors the helper used by the mobile-viewport
/// test).
Future<void> _preWarmFlameImageCache() async {
  try {
    final bytes = await rootBundle.load(
      'assets/images/ui_button_nine_patch.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
  } catch (_) {
    // Best-effort: the empty-state assertions below do not require
    // pixel-perfect chrome, only that the empty-state copy is present
    // and that no row body is rendered.
  }
}

/// Locate the single use-case with [useCaseName] inside the
/// [WidgetbookFolder] whose name matches [folderName], failing with a
/// readable matcher message if the folder or use case is missing.
WidgetbookUseCase _useCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories
      .whereType<WidgetbookFolder>()
      .firstWhere(
        (folder) => folder.name == folderName,
        orElse: () =>
            fail('Missing Widgetbook folder: $folderName (got: $directories)'),
      );
  final children = folder.children ?? const <WidgetbookNode>[];
  final useCase = children
      .whereType<WidgetbookUseCase>()
      .firstWhere(
        (uc) => uc.name == useCaseName,
        orElse: () => fail(
          'Missing use case "$useCaseName" in folder "$folderName" '
          '(got: ${children.map((c) => c.name).toList()})',
        ),
      );
  return useCase;
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_preWarmFlameImageCache);

  group('Diplomacy Panel Widgetbook empty-state story (Refs #2863 S7)', () {
    testWidgets(
      'use case is wired into diplomacyPanelDirectories under the canonical '
      'folder + name',
      (WidgetTester tester) async {
        final useCase = _useCase(
          diplomacyPanelDirectories,
          folderName: 'Diplomacy Panel',
          useCaseName: 'No factions discovered (empty state)',
        );
        // Smoke: the getter returns a builder closure (the constructor
        // contract for `WidgetbookUseCase`). The deeper pump assertion
        // lives in the next test so this one fails fast on wiring
        // regressions even if the panel itself becomes expensive to
        // mount.
        expect(useCase.builder, isNotNull);
      },
    );

    testWidgets(
      'builder pumps under editorialMonocle without exceptions and renders '
      'the three always-visible section headings plus the '
      'diplomacy_panel_noTribes copy with no faction rows',
      (WidgetTester tester) async {
        // Give the panel a generous surface so the empty-state padding
        // and the bottom mode bar both fit within the test viewport
        // without overflow exceptions.
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(800, 600));

        final useCase = _useCase(
          diplomacyPanelDirectories,
          folderName: 'Diplomacy Panel',
          useCaseName: 'No factions discovered (empty state)',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (BuildContext ctx) => useCase.builder(ctx),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          tester.takeException(),
          isNull,
          reason:
              'Empty-state story must pump without exceptions per '
              'SPEC/ui/diplomacy-panel.md § Widgetbook and the AC '
              '"Empty-state Widgetbook story renders headings + tribe '
              'placeholder".',
        );

        // Positive 1: the three section headings are always rendered,
        // even when their sections are empty (SPEC § Section headings,
        // Refs #3341).
        expect(
          find.text('Great Powers'),
          findsOneWidget,
          reason:
              'Empty-state story must paint the "Great Powers" section '
              'heading even when no Great Power is discovered.',
        );
        expect(
          find.text('Minor Nations'),
          findsOneWidget,
          reason:
              'Empty-state story must paint the "Minor Nations" section '
              'heading even when no Minor Nation is discovered.',
        );
        expect(
          find.text('Tribes'),
          findsOneWidget,
          reason:
              'Empty-state story must paint the "Tribes" section heading '
              'even when no tribe is contacted.',
        );

        // Positive 2: the localized Tribes empty placeholder copy from
        // `diplomacy_panel_noTribes` ("No tribes contacted yet.") must
        // render exactly once beneath the Tribes heading.
        expect(
          find.text('No tribes contacted yet.'),
          findsOneWidget,
          reason:
              'Empty-state story must surface the diplomacy_panel_noTribes '
              'l10n copy when no tribe is contacted.',
        );

        // Negative regression guard: no faction-row body should be in
        // the tree (rows is empty → no `_DiplomacyRow` keyed bodies).
        final Finder rowBodyFinder = find.byWidgetPredicate(
          (Widget w) {
            final Key? key = w.key;
            if (key is! ValueKey<String>) return false;
            return key.value.startsWith(kDiplomacyRowBodyKeyPrefix);
          },
          description:
              'faction-row body keyed by kDiplomacyRowBodyKeyPrefix',
        );
        expect(
          rowBodyFinder,
          findsNothing,
          reason:
              'Empty-state story must not paint any faction-row body when '
              'no factions are discovered (rows must be empty).',
        );
      },
    );
  });
}
