// Widget test pin for the `Tech Tree` → `Slots — funding & turn preview`
// Widgetbook use cases added by Refs #3512.
//
// Pins the SPEC contract from `SPEC/ui/technology-panel.md` § Widgetbook
// (funding & turn-preview stories) and § Acceptance criteria
// ("Funding & turn-preview Widgetbook coverage"):
//
//  1. Both the desktop and `360 × 640 dp` mobile use cases are wired into the
//     public `techTreeDirectories` getter under the canonical `Tech Tree`
//     folder + names (so renaming or removing them surfaces here in CI before
//     reviewers lose the editable funding / turn-preview stories).
//  2. The desktop builder mounts without exceptions under the editorial-
//     monocle theme and, for each of the three assigned slots, renders the
//     `SlotFundingToggleRow` (all five `ResearchFundingLevel` toggles) plus the
//     dual-segment turn preview (anticipated segment B + RP delta), since the
//     seeded treasury keeps every slot above the research debt floor.
//  3. The mobile builder mounts without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp) frame and still renders the toggles and
//     dual-segment preview for the assigned slots.

import 'package:colonizethis_models/colonizethis_models.dart'
    show ResearchFundingLevel;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/features/game/widgets/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology_slot_funding_toggles.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'support/widgetbook_test_harness.dart';

/// The three research slots seeded as assigned + editable by
/// `technologyFundingPreviewFixture` (SPEC/ui/technology-panel.md § Widgetbook).
const int _kAssignedSlots = 3;

const String _kFolderName = 'Tech Tree';
const String _kDesktopUseCaseName = 'Slots — funding & turn preview';
const String _kMobileUseCaseName = 'Slots — funding & turn preview (mobile)';

/// Locate the single use case with [useCaseName] inside the [WidgetbookFolder]
/// whose name matches [folderName], failing with a readable matcher message if
/// the folder or use case is missing.
WidgetbookUseCase findWidgetbookUseCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories.whereType<WidgetbookFolder>().firstWhere(
        (folder) => folder.name == folderName,
        orElse: () =>
            fail('Missing Widgetbook folder: $folderName (got: $directories)'),
      );
  final children = folder.children ?? const <WidgetbookNode>[];
  return children.whereType<WidgetbookUseCase>().firstWhere(
        (uc) => uc.name == useCaseName,
        orElse: () => fail(
          'Missing use case "$useCaseName" in folder "$folderName" '
          '(got: ${children.map((c) => c.name).toList()})',
        ),
      );
}

Future<void> _pumpUseCase(WidgetTester tester, WidgetbookUseCase useCase) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void _expectFundingTogglesAndPreview(WidgetTester tester) {
  for (var slot = 0; slot < _kAssignedSlots; slot++) {
    // Positive: all five funding toggles render for each assigned slot.
    for (final level in ResearchFundingLevel.values) {
      expect(
        find.byKey(SlotFundingToggleRow.toggleKey(slot, level)),
        findsOneWidget,
        reason:
            'Assigned slot $slot must expose the ${level.name} funding toggle '
            '(SPEC/ui/technology-panel.md § Slot funding controls).',
      );
    }
    // Positive: the dual-segment turn preview (anticipated segment B + RP
    // delta) renders for each assigned slot because the seeded treasury keeps
    // the slot above the research debt floor.
    expect(
      find.byKey(ResearchSlotTurnPreviewView.anticipatedSegmentKey(slot)),
      findsOneWidget,
      reason:
          'Assigned slot $slot must render the anticipated segment B of the '
          'dual-segment turn preview (SPEC § Slot turn preview).',
    );
    expect(
      find.byKey(ResearchSlotTurnPreviewView.rpDeltaKey(slot)),
      findsOneWidget,
      reason:
          'Assigned slot $slot must render the anticipated RP delta control '
          '(SPEC § Slot turn preview).',
    );
  }
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Technology funding & turn-preview Widgetbook stories (Refs #3512)', () {
    testWidgets(
      'both desktop + mobile use cases are wired into techTreeDirectories',
      (WidgetTester tester) async {
        final desktop = findWidgetbookUseCase(
          techTreeDirectories,
          folderName: _kFolderName,
          useCaseName: _kDesktopUseCaseName,
        );
        final mobile = findWidgetbookUseCase(
          techTreeDirectories,
          folderName: _kFolderName,
          useCaseName: _kMobileUseCaseName,
        );
        expect(desktop.builder, isNotNull);
        expect(mobile.builder, isNotNull);
      },
    );

    testWidgets(
      'desktop story renders funding toggles + dual-segment preview for each '
      'assigned slot without exceptions',
      (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(900, 900));

        final useCase = findWidgetbookUseCase(
          techTreeDirectories,
          folderName: _kFolderName,
          useCaseName: _kDesktopUseCaseName,
        );
        await _pumpUseCase(tester, useCase);

        expect(tester.takeException(), isNull);
        _expectFundingTogglesAndPreview(tester);
      },
    );

    testWidgets(
      'mobile story renders funding toggles + dual-segment preview inside the '
      '360 x 640 frame without exceptions',
      (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(360, 640));

        final useCase = findWidgetbookUseCase(
          techTreeDirectories,
          folderName: _kFolderName,
          useCaseName: _kMobileUseCaseName,
        );
        await _pumpUseCase(tester, useCase);

        expect(tester.takeException(), isNull);
        _expectFundingTogglesAndPreview(tester);
      },
    );
  });
}
