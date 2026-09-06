import 'package:colonizethis_app/features/game/widgets/units/civilian/explore_payoff_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _explorePayoffGame({
  required List<String> targetProvinceTiles,
  required List<String> otherProvinceTiles,
}) {
  const humanId = 'gp1';
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  return Game(
    id: 'g_explore_payoff',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: 'oldWorld', ownerId: humanId),
          Province(id: p2, regionId: 'oldWorld', ownerId: humanId),
        ],
        units: [
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: humanId,
            locationProvinceId: p1,
            tileKey: targetProvinceTiles.first,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: targetProvinceTiles,
          p2: otherProvinceTiles,
        },
      },
    ),
    players: const [
      Player(id: humanId, displayName: 'Human', isHuman: true),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

void main() {
  final l10n = AppLocalizationsEn();

  test('1-turn Explore gist uses singular Takes 1 turn (Refs #4733)', () {
    // ceil(3 * 1 / 3) = 1
    final game = _explorePayoffGame(
      targetProvinceTiles: const ['oldWorld|p1|0|0'],
      otherProvinceTiles: const [
        'oldWorld|p2|0|0',
        'oldWorld|p2|1|0',
        'oldWorld|p2|2|0',
      ],
    );
    expect(
      explorePayoffGistForTile(
        l10n: l10n,
        game: game,
        tileKey: 'oldWorld|p1|0|0',
        enabled: true,
      ),
      'After this work: this whole province becomes fully visible · Takes 1 turn',
    );
  });

  test('multi-turn Explore gist uses plural Takes N turns (Refs #4733)', () {
    // ceil(3 * 3 / 3) = 3
    final game = _explorePayoffGame(
      targetProvinceTiles: const [
        'oldWorld|p1|0|0',
        'oldWorld|p1|1|0',
        'oldWorld|p1|2|0',
      ],
      otherProvinceTiles: const ['oldWorld|p2|0|0'],
    );
    expect(
      explorePayoffGistForTile(
        l10n: l10n,
        game: game,
        tileKey: 'oldWorld|p1|0|0',
        enabled: true,
      ),
      'After this work: this whole province becomes fully visible · Takes 3 turns',
    );
  });

  test('Explore gist hides when disabled or observe (Refs #4733)', () {
    final game = _explorePayoffGame(
      targetProvinceTiles: const ['oldWorld|p1|0|0'],
      otherProvinceTiles: const [
        'oldWorld|p2|0|0',
        'oldWorld|p2|1|0',
        'oldWorld|p2|2|0',
      ],
    );
    expect(
      explorePayoffGistForTile(
        l10n: l10n,
        game: game,
        tileKey: 'oldWorld|p1|0|0',
        enabled: false,
      ),
      isNull,
    );
    expect(
      explorePayoffGistForTile(
        l10n: l10n,
        game: game,
        tileKey: 'oldWorld|p1|0|0',
        enabled: true,
        canMutateViaUi: false,
      ),
      isNull,
    );
  });

  test('Explore gist line helper matches l10n pluralization', () {
    expect(
      explorePayoffGistLine(l10n: l10n, turns: 1),
      'After this work: this whole province becomes fully visible · Takes 1 turn',
    );
    expect(
      explorePayoffGistLine(l10n: l10n, turns: 2),
      'After this work: this whole province becomes fully visible · Takes 2 turns',
    );
  });
}
