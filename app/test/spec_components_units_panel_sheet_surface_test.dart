/// Pins the [`SPEC/ui/components/units-panel-sheet-surface.md`](
/// ../../../SPEC/ui/components/units-panel-sheet-surface.md) component spec
/// authored for issue #3514 (Align unit panels visual chrome — bottom-sheet
/// host chrome, owner decision #4).
///
/// `UnitsPanelSheetSurface` is the shared modal-bottom-sheet frame consumed
/// by three player-unit screen specs (stable ids `UNIT10001`, `UNIT20001`,
/// `UNIT30001`). Per `colonizethis-ui-documentation.mdc` § *Component specs*,
/// a composite reused by multiple screen specs must have its own
/// `kebab-name.md` under `SPEC/ui/components/`.
///
/// These are deliberately static-text checks (file reads + regex searches);
/// the runtime Given–When–Then contract is exercised by
/// `app/test/units_panel_sheet_surface_test.dart`.
///
/// Refs #3514.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/units-panel-sheet-surface.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();

  group('SPEC/ui/components/units-panel-sheet-surface.md (#3514)', () {
    test('spec file exists and is non-empty', () {
      final file = File(_kSpecPath);
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'The composite-component spec for UnitsPanelSheetSurface must '
            'live at SPEC/ui/components/units-panel-sheet-surface.md per '
            'colonizethis-ui-documentation.mdc § Component specs.',
      );
      expect(file.readAsStringSync().trim(), isNotEmpty);
    });

    test('spec declares the canonical component-spec sections', () {
      final body = _readSpec();
      for (final heading in <String>[
        '## Purpose',
        '## Widget contract',
        '## Layout / wireframe',
        '## Behavior',
        '## Consumers',
        '## Acceptance criteria (Given–When–Then)',
        '## Tests',
        '## Related',
      ]) {
        expect(
          body,
          contains(heading),
          reason: 'spec must declare the canonical "$heading" section.',
        );
      }
    });

    test('spec lists all three unit-panel consumers by stable screen ID', () {
      final body = _readSpec();
      for (final consumerId in <String>['UNIT10001', 'UNIT20001', 'UNIT30001']) {
        expect(
          body,
          contains(consumerId),
          reason: 'spec must enumerate consumer screen ID $consumerId.',
        );
      }
    });

    test('spec encodes the canonical sheet-chrome tokens and constants', () {
      final body = _readSpec();
      for (final token in <String>[
        'topEdgeWidth',
        'topCornerRadius',
        'accent-dim',
        'EditorialMonoclePalette.surface',
        'EditorialMonoclePalette.bgDeep',
      ]) {
        expect(
          body,
          contains(token),
          reason:
              'spec must restate the canonical sheet-chrome marker "$token" '
              'so the host-chrome contract is documented at the SPEC level.',
        );
      }
    });

    test('spec is at most 1000 words (colonizethis-spec-required.mdc)', () {
      final words = _readSpec()
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
      expect(
        words.length <= 1000,
        isTrue,
        reason:
            'SPEC documents must stay under the 1000-word ceiling. Current '
            'word count is ${words.length}.',
      );
    });

    test('components README index lists the UnitsPanelSheetSurface row', () {
      final body = File(_kComponentsReadmePath).readAsStringSync();
      expect(body, contains('UnitsPanelSheetSurface'));
      expect(body, contains('units-panel-sheet-surface.md'));
    });
  });
}
