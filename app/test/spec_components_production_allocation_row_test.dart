/// Pins the [`SPEC/ui/components/production-allocation-row.md`](
/// ../../../SPEC/ui/components/production-allocation-row.md) component
/// spec authored as part of issue #2914 S9 (Refactor app/lib UI to
/// consolidate editorial-monocle design system — Phase 1 step S9:
/// populate `SPEC/ui/components/` with composite-component specs for
/// shared abstractions).
///
/// `ProductionAllocationRow` is the canonical per-recipe row composite
/// consumed by the Production panel (stable screen id `GAME20001`).
/// Per `colonizethis-ui-documentation.mdc` § *Component specs*, a
/// composite that is reused or extracted from a screen spec must have
/// its own `kebab-name.md` under `SPEC/ui/components/` rather than
/// duplicating the layout in the host screen spec. Issue #2914 § 6
/// explicitly enumerates "production allocation rows" as one of the
/// missing composite specs.
///
/// These tests are deliberately static-text checks (file reads + regex
/// searches): the canonical Given–When–Then runtime contract for the
/// widget itself is exercised by the existing
/// `app/test/production_allocation_row_buttons_test.dart`,
/// `app/test/production_allocation_row_chrome_test.dart`, and
/// `app/test/production_allocation_provider_test.dart` widget tests;
/// the goal here is to ensure the SPEC stays present and aligned with
/// the documentation rule even if future refactors move the widget
/// around.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/production-allocation-row.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();
  group(
    'SPEC/ui/components/production-allocation-row.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(_kSpecPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'The composite-component spec for ProductionAllocationRow '
                'must live at SPEC/ui/components/production-allocation-row.md '
                'per colonizethis-ui-documentation.mdc § Component specs and '
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
        'spec enumerates the GAME20001 consumer (production-panel.md) by '
        'stable screen ID and spec link',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('GAME20001'),
            reason:
                'spec must enumerate consumer screen ID GAME20001 so '
                'future refactors can reverse-trace the screen that '
                'depends on this composite.',
          );
          expect(
            body,
            contains('production-panel.md'),
            reason:
                'spec must link to the production-panel.md consumer spec '
                'so reviewers can navigate to the host wireframe.',
          );
        },
      );

      test(
        'spec encodes the canonical slider cap and step-button surface '
        'constants for regression guards',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('kProductionAllocationSliderCap = 50'),
            reason:
                'spec must restate the canonical slider cap so reviewers do '
                'not have to cross-reference the implementation to confirm '
                'the per-recipe maxAchievable clamp contract.',
          );
          expect(
            body,
            contains('kProductionAllocationStepButtonSize = 26'),
            reason:
                'spec must restate the canonical 26 dp step-button surface '
                'size shared with the Available subpanel Labour Controls.',
          );
          expect(
            body,
            contains('kProductionAllocationStepButtonDisabledOpacity'),
            reason:
                'spec must reference the canonical disabled-opacity '
                'constant (0.3) so the editorial-monocle dark contract is '
                'documented at the SPEC level.',
          );
          expect(
            body,
            contains('ProductionAllocationRowChrome'),
            reason:
                'spec must name ProductionAllocationRowChrome so the inner '
                'gradient-+-border surface contract is traceable from the '
                'composite spec.',
          );
          expect(
            body,
            contains('ProductionStepButtonSurface'),
            reason:
                'spec must reference ProductionStepButtonSurface so the '
                'shared inner button chrome (also used by Labour Controls) '
                'stays discoverable.',
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
                'cross-reference the CtSlider / StrictAssetIcon atoms.',
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
        'components README index lists the ProductionAllocationRow row '
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
            contains('ProductionAllocationRow'),
            reason:
                'README index must enumerate ProductionAllocationRow so '
                'the composite is discoverable from the directory landing '
                'page (issue #2914 S9).',
          );
          expect(
            body,
            contains('production-allocation-row.md'),
            reason:
                'README index row must link to the spec file path.',
          );
          expect(
            body,
            contains('GAME20001'),
            reason:
                'README index row for ProductionAllocationRow must '
                'reference the Production panel stable screen id '
                'GAME20001.',
          );
        },
      );
    },
  );
}
