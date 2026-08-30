// Power-comparison and filter helper tests for DiplomacyPanel rows (Refs #4305).
// Split from diplomacy_panel_rows_test.dart to stay under app test size gate.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

void main() {
  suppressLogsForTests();

  group('powerComparisonPercent', () {
    for (final c in <({String name, int gp, int player, int want})>[
      (
        name: 'GP stronger than player produces positive percentage',
        gp: 110,
        player: 100,
        want: 10,
      ),
      (
        name: 'GP weaker than player produces negative percentage',
        gp: 78,
        player: 100,
        want: -22,
      ),
      (
        name: 'equal scores produce zero percentage',
        gp: 100,
        player: 100,
        want: 0,
      ),
      (
        name: 'rounding uses banker-agnostic round() (positive mid)',
        gp: 105,
        player: 100,
        want: 5,
      ),
      (
        name: 'rounding uses banker-agnostic round() (positive high)',
        gp: 114,
        player: 100,
        want: 14,
      ),
      (
        name: 'zero playerPowerScore uses max(playerScore, 1) guard',
        gp: 50,
        player: 0,
        want: 5000,
      ),
      (name: 'zero/zero is finite 0% (no NaN)', gp: 0, player: 0, want: 0),
      (
        name: 'negative playerPowerScore is still guarded by max(.., 1)',
        gp: 50,
        player: -10,
        want: 6000,
      ),
    ]) {
      test(c.name, () {
        expect(powerComparisonPercent(c.gp, c.player), c.want);
      });
    }
  });

  group('formatPowerComparisonPercent', () {
    for (final c in <(int, String)>[
      (10, '+10%'),
      (1, '+1%'),
      (-22, '\u221222%'),
      (-1, '\u22121%'),
      (0, '0%'),
    ]) {
      test('formats ${c.$1} as ${c.$2}', () {
        expect(formatPowerComparisonPercent(c.$1), c.$2);
      });
    }

    test('negative percentage uses unicode minus sign (U+2212)', () {
      expect(formatPowerComparisonPercent(-22).startsWith('\u2212'), isTrue);
      expect(formatPowerComparisonPercent(-22).startsWith('-'), isFalse);
    });
  });

  group('powerComparisonTier (SPEC § Relative power line boundary table)', () {
    for (final c in <(int, PowerComparisonTier)>[
      (0, PowerComparisonTier.roughlyEqual),
      (10, PowerComparisonTier.roughlyEqual),
      (-10, PowerComparisonTier.roughlyEqual),
      (5, PowerComparisonTier.roughlyEqual),
      (-7, PowerComparisonTier.roughlyEqual),
      (11, PowerComparisonTier.superior),
      (30, PowerComparisonTier.superior),
      (22, PowerComparisonTier.superior),
      (31, PowerComparisonTier.vastlySuperior),
      (100, PowerComparisonTier.vastlySuperior),
      (4900, PowerComparisonTier.vastlySuperior),
      (-11, PowerComparisonTier.inferior),
      (-30, PowerComparisonTier.inferior),
      (-22, PowerComparisonTier.inferior),
      (-31, PowerComparisonTier.vastlyInferior),
      (-90, PowerComparisonTier.vastlyInferior),
    ]) {
      test('${c.$1} → ${c.$2}', () {
        expect(powerComparisonTier(c.$1), c.$2);
      });
    }
  });

  group('diplomacyFilterShowsKind', () {
    test('mode `all` shows every faction kind', () {
      for (final kind in FactionKind.values) {
        expect(
          diplomacyFilterShowsKind(DiplomacyFilterMode.all, kind),
          isTrue,
          reason: 'DiplomacyFilterMode.all must accept $kind',
        );
      }
    });

    for (final c
        in <
          ({String name, DiplomacyFilterMode mode, FactionKind kind, bool want})
        >[
          (
            name: 'greatPowersOnly shows Great Power',
            mode: DiplomacyFilterMode.greatPowersOnly,
            kind: FactionKind.greatPower,
            want: true,
          ),
          (
            name: 'greatPowersOnly hides Minor',
            mode: DiplomacyFilterMode.greatPowersOnly,
            kind: FactionKind.minor,
            want: false,
          ),
          (
            name: 'greatPowersOnly hides Tribe',
            mode: DiplomacyFilterMode.greatPowersOnly,
            kind: FactionKind.tribe,
            want: false,
          ),
          (
            name: 'minorsOnly shows Minor',
            mode: DiplomacyFilterMode.minorsOnly,
            kind: FactionKind.minor,
            want: true,
          ),
          (
            name: 'minorsOnly shows Tribe',
            mode: DiplomacyFilterMode.minorsOnly,
            kind: FactionKind.tribe,
            want: true,
          ),
          (
            name: 'minorsOnly hides Great Power',
            mode: DiplomacyFilterMode.minorsOnly,
            kind: FactionKind.greatPower,
            want: false,
          ),
        ]) {
      test(c.name, () {
        expect(diplomacyFilterShowsKind(c.mode, c.kind), c.want);
      });
    }
  });
}
