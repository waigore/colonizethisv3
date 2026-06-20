/// Pins the [`SPEC/ui/components/ct-game-feature-screen-shell.md`](
/// ../../../SPEC/ui/components/ct-game-feature-screen-shell.md) component
/// spec authored as part of issue #2914 S9 (Refactor app/lib UI to consolidate
/// editorial-monocle design system — Phase 1 step S9: populate
/// `SPEC/ui/components/` with composite-component specs for shared
/// abstractions).
///
/// The composite widget [CtGameFeatureScreenShell] is consumed by four
/// game-bound feature screens (`GAME20001` production, `GAME30001`
/// diplomacy, `GAME40001` technology, `GAME60001` trade). Per
/// `colonizethis-ui-documentation.mdc` § *Component specs*, a composite that
/// is reused by multiple screen specs must have its own `kebab-name.md` under
/// `SPEC/ui/components/` rather than duplicating the layout in each screen
/// spec.
///
/// These tests are deliberately static-text checks (file reads + regex
/// searches): the canonical Given–When–Then runtime contract for the widget
/// itself is exercised by the existing
/// `ct_game_feature_screen_shell_test.dart` widget tests; the goal here is
/// to ensure the SPEC stays present and aligned with the documentation rule
/// even if future refactors move the widget around.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath =
    '../SPEC/ui/components/ct-game-feature-screen-shell.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  suppressLogsForTests();
  group(
    'SPEC/ui/components/ct-game-feature-screen-shell.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(_kSpecPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'The composite-component spec for CtGameFeatureScreenShell '
                'must live at SPEC/ui/components/ct-game-feature-screen-shell.md '
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
        'spec lists all four game-feature-screen consumers by stable screen ID',
        () {
          final body = _readSpec();
          for (final consumerId in <String>[
            'GAME20001',
            'GAME30001',
            'GAME40001',
            'GAME60001',
          ]) {
            expect(
              body,
              contains(consumerId),
              reason:
                  'spec must enumerate consumer screen ID $consumerId so future '
                  'refactors can reverse-trace the feature screens that '
                  'depend on this composite.',
            );
          }
        },
      );

      test(
        'spec documents the live-game swap and listener-gating invariants',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('currentGameProvider'),
            reason:
                'spec must reference currentGameProvider so the live-game swap '
                'invariant (displayGame == live when live.id == game.id) is '
                'pinned at the SPEC level.',
          );
          expect(
            body,
            contains('GameToUIBusListener'),
            reason:
                'spec must reference GameToUIBusListener so the listener '
                'wrapping contract is pinned (issue #2914 S9 documentation '
                'goal).',
          );
          expect(
            body,
            contains('attachGameToUiListener'),
            reason:
                'spec must document the attachGameToUiListener opt-out used '
                'by Widgetbook / static stories.',
          );
        },
      );

      test(
        'spec enumerates both chrome paths (dark topBar vs legacy CtScreenShell)',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('topBar'),
            reason:
                'spec must document the topBar slot used by the dark editorial-'
                'monocle chrome path.',
          );
          expect(
            body,
            contains('CtScreenShell'),
            reason:
                'spec must document the legacy CtScreenShell chrome path so '
                'the two-path invariant is explicit.',
          );
          expect(
            body,
            contains('CtTopBar'),
            reason:
                'spec must reference CtTopBar so consumers know which catalog '
                'atom fills the topBar slot.',
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
        'components README index lists the new spec alongside the dialogue shell',
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
            contains('ct-game-feature-screen-shell.md'),
            reason:
                'components README index must reference the new component '
                'spec so reviewers can discover it from the directory entry.',
          );
          expect(
            body,
            contains('CtGameFeatureScreenShell'),
            reason:
                'components README index must name the composite widget so '
                'searches by widget name resolve to its spec.',
          );
        },
      );
    },
  );
}
