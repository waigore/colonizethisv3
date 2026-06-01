/// Pins the [`SPEC/ui/components/ct-transfer-list.md`](
/// ../../../SPEC/ui/components/ct-transfer-list.md) component spec
/// authored as part of issue #2914 S9 (Refactor app/lib UI to consolidate
/// editorial-monocle design system — Phase 1 step S9: populate
/// `SPEC/ui/components/` with composite-component specs for shared
/// abstractions).
///
/// `CtTransferList` is consumed by three dialog hosts: the
/// `TransferToHomeFleetDialog` (stable screen id `DLG40001`), the
/// Split Fleet dialog, and the Split Army dialog. Per
/// `colonizethis-ui-documentation.mdc` § *Component specs*, a composite
/// that is reused by multiple screen specs must have its own
/// `kebab-name.md` under `SPEC/ui/components/` rather than duplicating
/// the layout in each screen spec.
///
/// These tests are deliberately static-text checks (file reads + regex
/// searches): the canonical Given–When–Then runtime contract for the
/// widget itself is exercised by the existing
/// `app/test/widgets/ct_transfer_list_test.dart` widget tests and the
/// `app/test/dialogs_320dp_min_viewport_test.dart` viewport pin; the
/// goal here is to ensure the SPEC stays present and aligned with the
/// documentation rule even if future refactors move the widget around.
///
/// Refs #2914.
library;

import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';

const String _kSpecPath = '../SPEC/ui/components/ct-transfer-list.md';
const String _kComponentsReadmePath = '../SPEC/ui/components/README.md';

String _readSpec() => File(_kSpecPath).readAsStringSync();

void main() {
  group(
    'SPEC/ui/components/ct-transfer-list.md (#2914 S9)',
    () {
      test(
        'spec file exists and is non-empty',
        () {
          final file = File(_kSpecPath);
          expect(
            file.existsSync(),
            isTrue,
            reason:
                'The composite-component spec for CtTransferList must live '
                'at SPEC/ui/components/ct-transfer-list.md per '
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
                  'composite-component spec must declare the canonical "$heading" section.',
            );
          }
        },
      );

      test(
        'spec enumerates all three consumer surfaces (DLG40001 + Split '
        'Fleet + Split Army)',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('DLG40001'),
            reason:
                'spec must enumerate the Transfer to Home Fleet dialog by '
                'stable screen id DLG40001 so future refactors can '
                'reverse-trace the dialogs that depend on this composite.',
          );
          expect(
            body,
            contains('transfer-to-home-fleet-dialog.md'),
            reason: 'spec must link to transfer-to-home-fleet-dialog.md.',
          );
          expect(
            body,
            contains('naval-units-fleet-management.md'),
            reason:
                'spec must link to naval-units-fleet-management.md for the '
                'Split Fleet dialog consumer (no stable screen id at time of '
                'authoring).',
          );
          expect(
            body,
            contains('military-units-army-management.md'),
            reason:
                'spec must link to military-units-army-management.md for the '
                'Split Army dialog consumer (no stable screen id at time of '
                'authoring).',
          );
        },
      );

      test(
        'spec encodes the canonical narrow-stack threshold and scrim-token '
        'regression guards',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('kCtTransferListSideBySideMinWidth = 360'),
            reason:
                'spec must restate the canonical side-by-side threshold so '
                'reviewers do not have to cross-reference the implementation '
                'to confirm the narrow-stack contract (Refs #2914 S9, '
                'SPEC/ui/mobile-adaptation.md § 7).',
          );
          expect(
            body,
            contains('kMinViewportWidth = 320'),
            reason:
                'spec must reference the canonical minimum viewport pin '
                'documented in SPEC/ui/mobile-adaptation.md.',
          );
          expect(
            body,
            contains('Colors.black54'),
            reason:
                'spec must mention the legacy Colors.black54 literal in the '
                'regression-guard AC so future readers understand which hex '
                'literal is being banned (Refs #2914 S2 / #2867 R1).',
          );
        },
      );

      test(
        'spec links to the related composite catalog atoms and tracking '
        'issue #2914',
        () {
          final body = _readSpec();
          expect(
            body,
            contains('ct-full-screen-dialogue-shell.md'),
            reason:
                'spec must cross-link to the sibling full-screen dialogue '
                'shell so reviewers can discover the broader dialog chrome '
                'stack.',
          );
          expect(
            body,
            contains('pixel-art-ui-catalog.md'),
            reason:
                'spec must point back to the authoritative catalog atoms '
                '(CtTransferList, CtNinePatchButton, CtPanel) used by this '
                'composite.',
          );
          expect(
            body,
            contains('#2914'),
            reason:
                'spec must reference the tracking issue so future agents can '
                'navigate from the spec to the umbrella refactor.',
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
        'components README index lists the CtTransferList row '
        '(negative regression guard — README must not be deleted while '
        'individual specs live under it)',
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
          expect(
            body,
            contains('ct-transfer-list.md'),
            reason:
                'README index must include a row for the new CtTransferList '
                'composite spec so reviewers can discover it from the '
                'directory index.',
          );
          expect(
            body,
            contains('DLG40001'),
            reason:
                'README index row for CtTransferList must reference the '
                'Transfer to Home Fleet stable screen id DLG40001.',
          );
        },
      );
    },
  );
}
