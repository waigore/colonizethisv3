/// Pins the [`SPEC/ui/components/units-panel-shell.md`](
/// ../../../SPEC/ui/components/units-panel-shell.md) component spec
/// authored as part of issue #2914 S9 (Refactor app/lib UI to consolidate
/// editorial-monocle design system — Phase 1 step S9: populate
/// `SPEC/ui/components/` with composite-component specs for shared
/// abstractions).
///
/// `UnitsPanelShell` is the shared chrome consumed by three player-unit
/// screen specs (stable ids `UNIT10001`, `UNIT20001`, `UNIT30001`). Per
/// `colonizethis-ui-documentation.mdc` § *Component specs*, a composite
/// that is reused by multiple screen specs must have its own
/// `kebab-name.md` under `SPEC/ui/components/` rather than duplicating
/// the layout in each screen spec.
///
/// These tests are deliberately static-text checks (file reads + regex
/// searches): the canonical Given–When–Then runtime contract for the
/// widget itself is exercised by the existing
/// `app/test/units_panel_shared_widgets_test.dart` widget tests and the
/// `app/test/unit_panels_320dp_min_viewport_test.dart` viewport pin;
/// the goal here is to ensure the SPEC stays present and aligned with
/// the documentation rule even if future refactors move the widget
/// around.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/units-panel-shell.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();
  group(
    'SPEC/ui/components/units-panel-shell.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(_kSpecPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'The composite-component spec for UnitsPanelShell must live '
                'at SPEC/ui/components/units-panel-shell.md per '
                'colonizethis-ui-documentation.mdc § Component specs and '
                'issue #2914 S9.',
          );
          final body = file.readAsStringSync();
          expect(
            body.trim(),
            isNotEmpty,
            reason: 'spec must not be empty',
          );
        },
      );

      test(
        'spec declares all canonical sections required by the components '
        'README template (Purpose / Widget contract / Layout / Behavior / '
        'Consumers / Acceptance criteria / Tests / Related)',
        () {
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
              reason:
                  'composite-component spec must declare the canonical '
                  '"$heading" section.',
            );
          }
        },
      );

      test(
        'spec lists all three unit-panel consumers by stable screen ID',
        () {
          final body = _readSpec();
          for (final consumerId in <String>[
            'UNIT10001',
            'UNIT20001',
            'UNIT30001',
          ]) {
            expect(
              body,
              contains(consumerId),
              reason:
                  'spec must enumerate consumer screen ID $consumerId so '
                  'future refactors can reverse-trace the unit panels that '
                  'depend on this composite.',
            );
          }
          for (final consumerSpecFile in <String>[
            'civilian-units-panel.md',
            'military-units-panel.md',
            'naval-units-panel.md',
          ]) {
            expect(
              body,
              contains(consumerSpecFile),
              reason:
                  'spec must link to the consumer screen spec '
                  '$consumerSpecFile so reviewers can navigate to the '
                  'host wireframes.',
            );
          }
        },
      );

      test(
        'spec encodes the canonical default panel constraints and the '
        'EditorialMonoclePalette.muted empty-state contract',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('maxWidth: 400'),
            reason:
                'spec must restate the canonical maxWidth: 400 default so '
                'future readers do not have to cross-reference the source '
                'to confirm the bottom-sheet sizing contract.',
          );
          expect(
            body,
            contains('maxHeight: 500'),
            reason:
                'spec must restate the canonical maxHeight: 500 default '
                'matching UnitsPanelShell.defaultPanelConstraints.',
          );
          expect(
            body,
            contains('defaultPanelConstraints'),
            reason:
                'spec must mention the exposed '
                'UnitsPanelShell.defaultPanelConstraints constant so the '
                'consumer override path (naval >= 1280 dp) is traceable.',
          );
          expect(
            body,
            contains('EditorialMonoclePalette.muted'),
            reason:
                'spec must reference the canonical muted palette token '
                'used by the empty-state copy so the editorial-monocle '
                'dark contract is documented at the SPEC level.',
          );
        },
      );

      test(
        'spec links to the catalog atoms and tracking issue #2914',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('pixel-art-ui-catalog.md'),
            reason:
                'spec must link back to the catalog so reviewers can '
                'cross-reference the CtPanel / CtTopBar atoms.',
          );
          expect(
            body,
            contains('#2914'),
            reason:
                'spec must reference tracking issue #2914 so progress on '
                'the umbrella S9 step is discoverable from the file.',
          );
        },
      );

      test(
        'spec is at most 1000 words (colonizethis-spec-required.mdc § Layout)',
        () {
          final body = _readSpec();
          final words = body
              .split(RegExp(r'\s+'))
              .where((token) => token.isNotEmpty)
              .toList();
          expect(
            words.length <= 1000,
            isTrue,
            reason:
                'SPEC documents must stay under the 1000-word ceiling per '
                'colonizethis-spec-required.mdc § Layout. Current word '
                'count is ${words.length}.',
          );
        },
      );

      test(
        'components README index lists the UnitsPanelShell row (negative '
        'regression guard — README must continue to enumerate every '
        'composite spec under it)',
        () {
          final readme = File(_kComponentsReadmePath);
          expect(
            readme.existsSync(),
            isTrue,
            reason:
                'SPEC/ui/components/README.md must remain in place so '
                'authoring rules for new composite specs stay discoverable.',
          );
          final body = readme.readAsStringSync();
          expect(
            body,
            contains('SPEC/ui/components/'),
            reason:
                'README must continue to introduce the components/ '
                'directory.',
          );
          expect(
            body,
            contains('UnitsPanelShell'),
            reason:
                'README index must enumerate UnitsPanelShell so the '
                'composite is discoverable from the directory landing '
                'page (issue #2914 S9).',
          );
          expect(
            body,
            contains('units-panel-shell.md'),
            reason:
                'README index row must link to the spec file path.',
          );
        },
      );
    },
  );
}
