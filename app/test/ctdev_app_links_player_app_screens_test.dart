/// Pins the SPEC cross-reference AC from issue #2750:
///
/// > "`SPEC/program/ctdev-app.md` 'Main Screens / Tabs' table (or equivalent
/// >  shell/game rows) links to `SPEC/ui/shell-screen.md` and
/// >  `SPEC/ui/game-screen.md`. No further expansion of `ctdev-app.md` screen
/// >  descriptions is required by this issue."
///
/// `ctdev-app.md` is the program-side spec for the ctdev developer tool and
/// does not own player-app screen rows. The AC is satisfied by a dedicated
/// "Related — Main player app screens" section in `ctdev-app.md` that
/// cross-references the two new player-app screen specs landed by the parent
/// slice (PR #2756). This pin reads `SPEC/program/ctdev-app.md` from disk and
/// fails if either relative link is removed, so the cross-reference cannot
/// silently regress.
///
/// Refs GitHub #2750.
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

const String _ctdevAppSpecRelativePath = 'SPEC/program/ctdev-app.md';

const String _shellScreenSpecLink = '../ui/shell-screen.md';
const String _gameScreenSpecLink = '../ui/game-screen.md';

String _readCtdevAppSpec() {
  final repoRoot = Directory.current.path;
  // `flutter test` from `app/` and `dart test` from repo root both need to
  // locate the spec; tolerate either CWD without bespoke runner config.
  final candidates = <File>[
    File('$repoRoot/$_ctdevAppSpecRelativePath'),
    File('$repoRoot/../$_ctdevAppSpecRelativePath'),
  ];
  for (final file in candidates) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail(
    'Could not locate `$_ctdevAppSpecRelativePath` at any of: '
    '${candidates.map((f) => f.path).join(', ')}. '
    'Issue #2750 SPEC-cross-reference pin must read the on-disk spec to '
    'guard the player-app screen links.',
  );
}

void main() {
  suppressLogsForTests();

  group(
    'SPEC/program/ctdev-app.md cross-references the main player app screens '
    '(Refs #2750)',
    () {
      late final String specBody = _readCtdevAppSpec();

      test('links to SPEC/ui/shell-screen.md via the documented relative path',
          () {
        expect(
          specBody.contains(_shellScreenSpecLink),
          isTrue,
          reason:
              'Issue #2750 AC requires `SPEC/program/ctdev-app.md` to point '
              'readers at the dedicated `SPEC/ui/shell-screen.md` for the '
              'player app shell screen. The relative link '
              '`$_shellScreenSpecLink` (from `SPEC/program/`) is the form '
              'documented in the new "Related — Main player app screens" '
              'section and matches the cross-reference style used elsewhere '
              'in `SPEC/program/`. Removing it strands a reader who lands on '
              'the ctdev tool spec and would otherwise miss the player-app '
              'screen contract.',
        );
      });

      test('links to SPEC/ui/game-screen.md via the documented relative path',
          () {
        expect(
          specBody.contains(_gameScreenSpecLink),
          isTrue,
          reason:
              'Issue #2750 AC requires `SPEC/program/ctdev-app.md` to point '
              'readers at the dedicated `SPEC/ui/game-screen.md` for the '
              'player app in-game screen. The relative link '
              '`$_gameScreenSpecLink` (from `SPEC/program/`) is the form '
              'documented in the new "Related — Main player app screens" '
              'section and matches the cross-reference style used elsewhere '
              'in `SPEC/program/`. Removing it strands a reader who lands on '
              'the ctdev tool spec and would otherwise miss the player-app '
              'in-game screen contract.',
        );
      });

      test(
        'lists both player-app screen pointers under a dedicated section '
        '(not in the ctdev "Main Screens / Tabs" table)',
        () {
          // Negative pin: the ctdev "Main Screens / Tabs" table documents the
          // *ctdev* dev tool screens (Init Game Config, Init Game Map Debug,
          // Running Game). Player-app screens must not be smuggled into that
          // table, because they are not ctdev features. The AC's "equivalent
          // shell/game rows" wording is satisfied by a separate, clearly
          // labelled cross-reference section, mirrored by this assertion.
          final mainScreensHeaderIdx = specBody.indexOf('## Main Screens / Tabs');
          final relatedPlayerAppHeaderIdx =
              specBody.indexOf('## Related — Main player app screens');

          expect(
            mainScreensHeaderIdx,
            greaterThanOrEqualTo(0),
            reason:
                'ctdev-app.md must keep its "Main Screens / Tabs" section so '
                'this negative pin can measure the boundary between ctdev '
                'screens and player-app cross-references.',
          );
          expect(
            relatedPlayerAppHeaderIdx,
            greaterThan(mainScreensHeaderIdx),
            reason:
                'The new "Related — Main player app screens" section must '
                'appear after the ctdev-screens table so player-app pointers '
                'live in their own section instead of polluting the ctdev '
                'screens table (Refs #2750 scope decision).',
          );

          final shellLinkIdx = specBody.indexOf(_shellScreenSpecLink);
          final gameLinkIdx = specBody.indexOf(_gameScreenSpecLink);
          expect(
            shellLinkIdx,
            greaterThan(relatedPlayerAppHeaderIdx),
            reason:
                'The shell-screen.md pointer must live in the "Related — '
                'Main player app screens" section to avoid implying ctdev '
                'hosts ShellScreen.',
          );
          expect(
            gameLinkIdx,
            greaterThan(relatedPlayerAppHeaderIdx),
            reason:
                'The game-screen.md pointer must live in the "Related — '
                'Main player app screens" section to avoid implying ctdev '
                'hosts GameScreen.',
          );
        },
      );
    },
  );
}
