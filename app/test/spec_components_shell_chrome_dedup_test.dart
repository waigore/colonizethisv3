/// Pins the two component specs authored for issue #3279 shell-chrome
/// deduplication:
///
/// * [`SPEC/ui/components/ct-dark-scaffold.md`](
///   ../../../SPEC/ui/components/ct-dark-scaffold.md) — §6 promotion of the
///   private `_DarkChromeShell` to the public `CtDarkScaffold`.
/// * [`SPEC/ui/components/ct-panel-with-top-bar.md`](
///   ../../../SPEC/ui/components/ct-panel-with-top-bar.md) — §5 extraction of
///   the shared `CtPanel` + `Column` + top-bar skeleton.
///
/// Per `colonizethis-ui-documentation.mdc` § *Component specs*, a composite
/// reused by multiple screens/shells must have its own `kebab-name.md` under
/// `SPEC/ui/components/`. These are static-text checks; the runtime contract
/// is exercised by `app/test/ct_dark_scaffold_test.dart` and
/// `app/test/ct_panel_with_top_bar_test.dart`.
library;

import 'dart:io' show File;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _kReadmePath = '../SPEC/ui/components/README.md';

const List<String> _kCanonicalHeadings = <String>[
  '## Purpose',
  '## Widget contract',
  '## Layout / wireframe',
  '## Behavior',
  '## Consumers',
  '## Acceptance criteria (Given–When–Then)',
  '## Tests',
  '## Related',
];

void _expectCanonicalSpec(String specPath) {
  final file = File(specPath);
  expect(
    file.existsSync(),
    isTrue,
    reason: 'composite-component spec must exist at $specPath per '
        'colonizethis-ui-documentation.mdc § Component specs (issue #3279).',
  );
  final body = file.readAsStringSync();
  expect(body.trim(), isNotEmpty, reason: 'spec must not be empty');
  for (final heading in _kCanonicalHeadings) {
    expect(
      body,
      contains(heading),
      reason: '$specPath must declare the canonical "$heading" section.',
    );
  }
  expect(
    body,
    contains('#3279'),
    reason: '$specPath must reference tracking issue #3279.',
  );
  final words = body
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
  expect(
    words.length <= 1000,
    isTrue,
    reason:
        'SPEC documents must stay under the 1000-word ceiling per '
        'colonizethis-spec-required.mdc § Layout. $specPath word count is '
        '${words.length}.',
  );
}

void main() {
  suppressLogsForTests();

  group('SPEC/ui/components shell-chrome dedup specs (#3279)', () {
    test('ct-dark-scaffold.md exists with canonical sections', () {
      _expectCanonicalSpec('../SPEC/ui/components/ct-dark-scaffold.md');
    });

    test('ct-panel-with-top-bar.md exists with canonical sections', () {
      _expectCanonicalSpec('../SPEC/ui/components/ct-panel-with-top-bar.md');
    });

    test('ct-dark-scaffold.md names its host composite consumer', () {
      final body =
          File('../SPEC/ui/components/ct-dark-scaffold.md').readAsStringSync();
      expect(
        body,
        contains('CtGameFeatureScreenShell'),
        reason: 'spec must enumerate the CtGameFeatureScreenShell consumer '
            'so the dark-chrome host is traceable.',
      );
    });

    test('ct-panel-with-top-bar.md names both consumers', () {
      final body = File('../SPEC/ui/components/ct-panel-with-top-bar.md')
          .readAsStringSync();
      for (final consumer in <String>['CtScreenShell', 'UnitsPanelShell']) {
        expect(
          body,
          contains(consumer),
          reason: 'spec must enumerate the $consumer consumer so the shared '
              'skeleton usage is traceable.',
        );
      }
    });

    test('components README index lists both new component rows', () {
      final body = File(_kReadmePath).readAsStringSync();
      for (final token in <String>[
        'CtDarkScaffold',
        'ct-dark-scaffold.md',
        'CtPanelWithTopBar',
        'ct-panel-with-top-bar.md',
      ]) {
        expect(
          body,
          contains(token),
          reason: 'README index must enumerate $token so the composite spec '
              'is discoverable from the directory landing page (#3279).',
        );
      }
    });
  });
}
