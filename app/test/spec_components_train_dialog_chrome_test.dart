/// Pins the [`SPEC/ui/components/train-dialog-chrome.md`](
/// ../../../SPEC/ui/components/train-dialog-chrome.md) component spec
/// authored as part of issue #2914 S9.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'spec_components_train_dialog_chrome_cases.dart';

String _readSpec() => File(kTrainDialogChromeSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();
  group(
    'SPEC/ui/components/train-dialog-chrome.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(kTrainDialogChromeSpecPath);
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
          for (final heading in kTrainDialogChromeRequiredHeadings) {
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
          expect(body, contains('UNIT40001'));
          expect(body, contains('UNIT50001'));
          expect(body, contains('train-civilians-dialog.md'));
          expect(body, contains('train-military-dialog.md'));
        },
      );

      test(
        'spec names every chrome widget and exported constant for '
        'regression guards',
        () {
          final body = _readSpec();
          for (final symbol in kTrainDialogChromeRequiredSymbols) {
            expect(
              body,
              contains(symbol),
              reason:
                  'spec must restate the canonical chrome symbol or '
                  'constant "$symbol".',
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
          for (final atom in kTrainDialogChromeCatalogAtoms) {
            expect(
              body,
              contains(atom),
              reason:
                  'spec must reference the Ct-* catalog atom "$atom".',
            );
          }
        },
      );

      test(
        'spec links to the catalog and tracking issue #2914',
        () {
          final body = _readSpec();
          expect(body, contains('pixel-art-ui-catalog.md'));
          expect(body, contains('#2914'));
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
                'SPEC documents must stay under the 1000-word ceiling. '
                'Current word count is ${words.length}.',
          );
        },
      );

      test(
        'components README index lists the TrainDialogChrome row '
        '(negative regression guard — README must continue to enumerate '
        'every composite spec under it)',
        () {
          final readme = File(kTrainDialogChromeComponentsReadmePath);
          expect(readme.existsSync(), isTrue);
          final body = readme.readAsStringSync();
          expect(body, contains('SPEC/ui/components/'));
          expect(body, contains('TrainDialogChrome'));
          expect(body, contains('train-dialog-chrome.md'));
          expect(body, contains('UNIT40001'));
          expect(body, contains('UNIT50001'));
        },
      );
    },
  );
}
