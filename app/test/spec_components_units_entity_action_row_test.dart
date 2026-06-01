/// Pins the [`SPEC/ui/components/units-entity-action-row.md`](
/// ../../../SPEC/ui/components/units-entity-action-row.md) component spec
/// authored as part of issue #2914 S9 (Refactor app/lib UI to consolidate
/// editorial-monocle design system — Phase 1 step S9: populate
/// `SPEC/ui/components/` with composite-component specs for shared
/// abstractions).
///
/// `UnitsEntityActionRow` is the shared per-entity row layout consumed
/// by three player-unit screen specs (stable ids `UNIT10001` civilian,
/// `UNIT20001` military, `UNIT30001` naval). Per
/// `colonizethis-ui-documentation.mdc` § *Component specs*, a composite
/// that is reused by multiple screen specs must have its own
/// `kebab-name.md` under `SPEC/ui/components/` rather than duplicating
/// the layout in each screen spec.
///
/// These tests are deliberately static-text checks (file reads + regex
/// searches): the canonical Given–When–Then runtime contract for the
/// widget itself is exercised by the existing
/// `app/test/units_panel_shared_widgets_test.dart` widget tests and the
/// `app/test/naval_units_panel_mockup_fidelity_test.dart` mockup pin;
/// the goal here is to ensure the SPEC stays present and aligned with
/// the documentation rule even if future refactors move the widget
/// around.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/units-entity-action-row.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();
  group(
    'SPEC/ui/components/units-entity-action-row.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(_kSpecPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'The composite-component spec for UnitsEntityActionRow must '
                'live at SPEC/ui/components/units-entity-action-row.md per '
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
        'spec encodes the canonical collapse breakpoints and dense '
        'mode contract',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('iconOnlyBreakpoint'),
            reason:
                'spec must name the iconOnlyBreakpoint prop so the '
                'default-mode collapse threshold is documented at the '
                'SPEC level.',
          );
          expect(
            body,
            contains('280'),
            reason:
                'spec must restate the canonical iconOnlyBreakpoint = 280 dp '
                'default so future readers do not have to cross-reference '
                'the source.',
          );
          expect(
            body,
            contains('70 * actions.length'),
            reason:
                'spec must document the dense-mode 70 dp * actions.length '
                'collapse heuristic so the naval Move + Split + Locate '
                'cluster contract is traceable.',
          );
          expect(
            body,
            contains('dense'),
            reason:
                'spec must reference the `dense` mode toggle that the '
                'naval panel opts into per R25.',
          );
          expect(
            body,
            contains('UnitsPanelRowChrome'),
            reason:
                'spec must name the outer chrome wrapper so the gradient '
                '+ accent-dim border contract is documented at the SPEC '
                'level.',
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
                'cross-reference the CtNinePatchButton atom.',
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
        'components README index lists the UnitsEntityActionRow row '
        '(negative regression guard — README must continue to enumerate '
        'every composite spec under it)',
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
            contains('UnitsEntityActionRow'),
            reason:
                'README index must enumerate UnitsEntityActionRow so the '
                'composite is discoverable from the directory landing '
                'page (issue #2914 S9).',
          );
          expect(
            body,
            contains('units-entity-action-row.md'),
            reason:
                'README index row must link to the spec file path.',
          );
        },
      );
    },
  );
}
