/// Pins SPEC/ui/components/production-allocation-row.md (#2914 S9).
/// README index: spec_components_production_allocation_row_readme_test.dart.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/production-allocation-row.md';

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
    },
  );
}
