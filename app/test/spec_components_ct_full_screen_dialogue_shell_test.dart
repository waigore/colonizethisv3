/// Pins the [`SPEC/ui/components/ct-full-screen-dialogue-shell.md`](
/// ../../../SPEC/ui/components/ct-full-screen-dialogue-shell.md) component
/// spec authored as part of issue #2914 S9 (Refactor app/lib UI to consolidate
/// editorial-monocle design system — Phase 1 step S9: populate
/// `SPEC/ui/components/` with composite-component specs for shared
/// abstractions).
///
/// The composite widget [CtFullScreenDialogueShell] is consumed by four
/// dialogue overlay screen specs (`OVL10001`, `OVL30001`, `OVL40001`, and
/// the pending-intervention overlay). Per
/// `colonizethis-ui-documentation.mdc` § *Component specs*, a composite that
/// is reused by multiple screen specs must have its own `kebab-name.md` under
/// `SPEC/ui/components/` rather than duplicating the layout in each screen
/// spec.
///
/// These tests are deliberately static-text checks (file reads + regex
/// searches): the canonical Given–When–Then runtime contract for the widget
/// itself is exercised by the existing
/// `ct_full_screen_dialogue_shell_test.dart` widget tests; the goal here is
/// to ensure the SPEC stays present and aligned with the documentation rule
/// even if future refactors move the widget around.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath =
    '../SPEC/ui/components/ct-full-screen-dialogue-shell.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  group(
    'SPEC/ui/components/ct-full-screen-dialogue-shell.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(_kSpecPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'The composite-component spec for CtFullScreenDialogueShell '
                'must live at SPEC/ui/components/ct-full-screen-dialogue-shell.md '
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
        'README template (Widget contract / Layout / Behavior / Consumers / '
        'Acceptance criteria)',
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
                  'composite-component spec must declare the canonical "$heading" section.',
            );
          }
        },
      );

      test(
        'spec lists all four overlay-screen consumers by stable screen ID',
        () {
          final body = _readSpec();
          for (final consumerId in <String>['OVL10001', 'OVL30001', 'OVL40001']) {
            expect(
              body,
              contains(consumerId),
              reason:
                  'spec must enumerate consumer screen ID $consumerId so future '
                  'refactors can reverse-trace the dialogue overlays that '
                  'depend on this composite.',
            );
          }
          expect(
            body,
            contains('pending-intervention-overlay.md'),
            reason:
                'spec must enumerate the pending-intervention overlay (no '
                'stable ID assigned at time of authoring) as a consumer.',
          );
        },
      );

      test(
        'spec encodes the canonical scrim token + Colors.black54 ban (positive '
        'and negative regression guards)',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('EditorialMonoclePalette.dialogScrim'),
            reason:
                'spec must reference the canonical scrim token so the '
                'editorial-monocle dark contract is documented at the SPEC '
                'level (Refs #2914 S2 / #2867 R1).',
          );
          expect(
            body,
            contains('Colors.black54'),
            reason:
                'spec must mention the legacy Colors.black54 literal in the '
                'regression-guard AC so future readers understand which hex '
                'literal is being banned.',
          );
        },
      );

      test(
        'spec encodes the canonical default props and links the spacing '
        'token table (CtSpacing.xl == 20 dp)',
        () {
          final body = _readSpec();
          expect(body, contains('defaultMaxWidth = 520'));
          expect(body, contains('defaultMaxHeight = 600'));
          expect(body, contains('CtSpacing.xl'));
          expect(
            body,
            contains('20 dp'),
            reason:
                'spec must restate the resolved CtSpacing.xl value so '
                'reviewers do not have to cross-reference the catalog to '
                'confirm the inner-padding default.',
          );
        },
      );

      test(
        'spec is at most 1000 words (colonizethis-spec-required.mdc § Layout)',
        () {
          final body = _readSpec();
          // Match the same word-counting heuristic as `wc -w` (whitespace
          // split, non-empty tokens) so the budget aligns with the rule.
          final words = body
              .split(RegExp(r'\s+'))
              .where((token) => token.isNotEmpty)
              .toList();
          expect(
            words.length <= 1000,
            isTrue,
            reason:
                'SPEC documents must stay under the 1000-word ceiling per '
                'colonizethis-spec-required.mdc § Layout. Current word count '
                'is ${words.length}.',
          );
        },
      );

      test(
        'components README still introduces the SPEC/ui/components/ directory '
        '(negative regression guard — components README must not be deleted '
        'while individual specs live under it)',
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
            reason: 'README must continue to introduce the components/ directory.',
          );
        },
      );
    },
  );
}
