import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Pins the SPEC content added by issue #2870 S0 (mobile-adaptation breakpoints
/// reconciled against the per-screen mockups).
///
/// AC (issue #2870 S0):
///   Given S0 has landed, when SPEC/ui/mobile-adaptation.md is read,
///   then § 4 includes a Main Menu ≤ 430 dp breakpoint rule citing
///   SPEC/ui/mockups/SHEL10002-main-menu.html, and the In-game shell entry
///   includes a measurement table for narrow minimap (90 × 70 dp),
///   left rail (26 × 26 dp), corner controls (24 × 24 dp), players bar (hidden),
///   and province panel (bottom, ~33 vh).
void main() {
  final repoRoot = _findRepoRoot(Directory.current);
  final specFile = File(
    p.join(repoRoot.path, 'SPEC', 'ui', 'mobile-adaptation.md'),
  );

  late String spec;

  setUpAll(() {
    expect(
      specFile.existsSync(),
      isTrue,
      reason: 'Expected SPEC/ui/mobile-adaptation.md at ${specFile.path}',
    );
    spec = specFile.readAsStringSync();
  });

  group('SPEC/ui/mobile-adaptation.md § 4 — issue #2870 S0', () {
    test('removes the stale "Main Menu: No breakpoint change" line', () {
      expect(
        spec,
        isNot(contains('No breakpoint change')),
        reason:
            'Issue #2870 S0 normalises mobile-adaptation.md against the main-menu mockup; '
            'the legacy "No breakpoint change" main-menu wording must be replaced.',
      );
    });

    test('declares a Main Menu ≤ 430 dp narrow breakpoint', () {
      expect(spec, contains('Main Menu (`≤ 430 dp`)'));
      expect(
        spec,
        contains('letter-spacing'),
        reason:
            'The 430 dp rule must capture the wood-panel label letter-spacing change.',
      );
      expect(
        spec,
        contains('0.04em'),
        reason:
            'The reduced letter-spacing value must match the mockup `@media (max-width: 430px)` rule.',
      );
      expect(
        spec,
        contains('24 px 12 px'),
        reason:
            'The menu-container padding override must match the mockup `@media (max-width: 430px)` rule.',
      );
    });

    test('cites the SHEL10002 main-menu mockup as the 430 dp source', () {
      expect(
        spec,
        contains('SPEC/ui/mockups/SHEL10002-main-menu.html'),
        reason:
            'AC requires citing the main-menu mockup as the visual source of truth.',
      );
    });

    test('declares the < 600 dp in-game shell measurement table', () {
      expect(spec, contains('In-game shell (`< 600 dp`)'));
      expect(
        spec,
        contains('SPEC/ui/mockups/GAME10001-game-screen.html'),
        reason:
            'AC requires citing the game-screen mockup for the narrow measurements.',
      );
    });

    test('measurement table pins minimap 90 × 70 dp narrow', () {
      expect(spec, contains('90 × 70 dp'));
      expect(spec, contains('Minimap panel'));
    });

    test(
      'measurement table pins left-rail 26 × 26 dp narrow vs 36 × 36 dp default',
      () {
        expect(spec, contains('Left-rail buttons'));
        expect(spec, contains('26 × 26 dp'));
        expect(spec, contains('36 × 36 dp'));
      },
    );

    test(
      'measurement table pins corner controls 24 × 24 dp narrow vs 32 × 32 dp default',
      () {
        expect(spec, contains('Corner controls'));
        expect(spec, contains('24 × 24 dp'));
        expect(spec, contains('32 × 32 dp'));
      },
    );

    test('measurement table records players bar hidden at narrow', () {
      expect(spec, contains('Players bar'));
      expect(
        spec,
        contains('Hidden (not present in widget tree)'),
        reason:
            'Players bar must be removed from the widget tree at narrow per Req 6 of issue #2870.',
      );
    });

    test(
      'measurement table records province/sea detail bottom 33 vh at narrow',
      () {
        expect(spec, contains('Province / sea detail'));
        expect(spec, contains('33 vh'));
        expect(
          spec,
          contains('accent-dim top border'),
          reason:
              'Narrow province/sea detail must declare the accent-dim top border per in-game-shell-narrow.md.',
        );
      },
    );

    test('summary table reflects the new Main Menu breakpoint', () {
      expect(spec, contains('Narrow breakpoint'));
      expect(spec, contains('tight ≤ 430 dp'));
      expect(spec, contains('stacked < 500 dp'));
      expect(spec, contains('side menu < 600 dp'));
    });
  });
}

Directory _findRepoRoot(Directory start) {
  Directory current = start.absolute;
  while (true) {
    final pubspec = File(p.join(current.path, 'pubspec.yaml'));
    final melosWorkspace = Directory(p.join(current.path, 'SPEC', 'ui'));
    if (pubspec.existsSync() && melosWorkspace.existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      fail(
        'Could not locate the ColonizeThis repo root starting from '
        '${start.absolute.path}; missing pubspec.yaml + SPEC/ui.',
      );
    }
    current = parent;
  }
}
