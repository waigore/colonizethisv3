/// Pins the [`SPEC/ui/components/train-dialog-chrome.md`](
/// ../../../SPEC/ui/components/train-dialog-chrome.md) component spec
/// authored as part of issue #2914 S9 (Refactor app/lib UI to
/// consolidate editorial-monocle design system — Phase 1 step S9:
/// populate `SPEC/ui/components/` with composite-component specs for
/// shared abstractions).
///
/// `TrainDialogChrome` is the canonical header / divider / resource-bar
/// / resource-chip / row-surface chrome composed inside `CtDialogShell`
/// by both the Train Civilians dialog (stable screen id `UNIT40001`)
/// and the Train Military dialog (stable screen id `UNIT50001`). Per
/// `colonizethis-ui-documentation.mdc` § *Component specs*, a composite
/// reused by multiple screen specs must live under
/// `SPEC/ui/components/<kebab-name>.md` rather than being duplicated in
/// each consumer spec.
///
/// These tests are deliberately static-text checks (file reads + regex
/// searches): the canonical Given–When–Then runtime contract for the
/// individual chrome widgets is exercised by
/// `app/test/train_dialog_chrome_test.dart`,
/// `app/test/train_dialogs_320dp_min_viewport_test.dart`, and the two
/// consumer-dialog widget tests. The goal here is to ensure the SPEC
/// stays present and aligned with the documentation rule even if future
/// refactors move the widget file around.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/train-dialog-chrome.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();
  group(
    'SPEC/ui/components/train-dialog-chrome.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(_kSpecPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'The composite-component spec for TrainDialogChrome must '
                'live at SPEC/ui/components/train-dialog-chrome.md per '
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
        'spec enumerates the UNIT40001 + UNIT50001 consumers by stable '
        'screen ID and spec link',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('UNIT40001'),
            reason:
                'spec must enumerate consumer screen ID UNIT40001 (Train '
                'Civilians dialog) so future refactors can reverse-trace '
                'the screen that depends on this composite.',
          );
          expect(
            body,
            contains('UNIT50001'),
            reason:
                'spec must enumerate consumer screen ID UNIT50001 (Train '
                'Military dialog) so future refactors can reverse-trace '
                'the screen that depends on this composite.',
          );
          expect(
            body,
            contains('train-civilians-dialog.md'),
            reason:
                'spec must link to the train-civilians-dialog.md consumer '
                'spec so reviewers can navigate to the host dialog.',
          );
          expect(
            body,
            contains('train-military-dialog.md'),
            reason:
                'spec must link to the train-military-dialog.md consumer '
                'spec so reviewers can navigate to the host dialog.',
          );
        },
      );

      test(
        'spec names every chrome widget and exported constant for '
        'regression guards',
        () {
          final body = _readSpec();
          for (final symbol in <String>[
            'TrainDialogHeader',
            'TrainDialogSectionDivider',
            'TrainDialogResourceBar',
            'TrainDialogResourceChip',
            'TrainDialogUnitRowSurface',
            'kTrainDialogLockedOpacity = 0.5',
            'kTrainDialogTitleLetterSpacing = 0.05',
          ]) {
            expect(
              body,
              contains(symbol),
              reason:
                  'spec must restate the canonical chrome symbol or '
                  'constant "$symbol" so reviewers do not have to '
                  'cross-reference the implementation to confirm the '
                  'dark editorial-monocle contract.',
            );
          }
        },
      );

      test(
        'spec names the canonical catalog atoms it composes (CtDialogShell, '
        'CtNinePatchButton, CtBrassDivider, CtGradients, '
        'EditorialMonoclePalette)',
        () {
          final body = _readSpec();
          for (final atom in <String>[
            'CtDialogShell',
            'CtNinePatchButton',
            'CtBrassDivider',
            'CtGradients',
            'EditorialMonoclePalette',
          ]) {
            expect(
              body,
              contains(atom),
              reason:
                  'spec must reference the Ct-* catalog atom "$atom" so '
                  'the composite chrome stays traceable to its '
                  'design-system sources.',
            );
          }
        },
      );

      test(
        'spec links to the catalog and tracking issue #2914',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('pixel-art-ui-catalog.md'),
            reason:
                'spec must link back to the catalog so reviewers can '
                'cross-reference the catalog atoms it composes.',
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
        'components README index lists the TrainDialogChrome row '
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
            contains('TrainDialogChrome'),
            reason:
                'README index must enumerate TrainDialogChrome so the '
                'composite is discoverable from the directory landing '
                'page (issue #2914 S9).',
          );
          expect(
            body,
            contains('train-dialog-chrome.md'),
            reason:
                'README index row must link to the spec file path.',
          );
          expect(
            body,
            contains('UNIT40001'),
            reason:
                'README index row for TrainDialogChrome must reference '
                'the Train Civilians dialog stable screen id UNIT40001.',
          );
          expect(
            body,
            contains('UNIT50001'),
            reason:
                'README index row for TrainDialogChrome must reference '
                'the Train Military dialog stable screen id UNIT50001.',
          );
        },
      );
    },
  );
}
