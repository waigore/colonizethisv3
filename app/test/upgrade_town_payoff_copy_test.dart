import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

const _tile = 'oldWorld|p1|0|0';
const _humanId = 'gp1';

Game _game({required int townLevel}) {
  const p1 = 'oldWorld|p1';
  return Game(
    id: 'g_upgrade_town_payoff_copy',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: 'oldWorld',
            ownerId: _humanId,
            townDevelopmentLevel: townLevel,
            townTileKey: _tile,
          ),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: _humanId,
            locationProvinceId: p1,
            tileKey: _tile,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: [_tile],
        },
      },
    ),
    players: const [Player(id: _humanId, displayName: 'Human', isHuman: true)],
    minorNations: const [],
    tribes: const [],
  );
}

String? _gistFor({
  required AppLocalizationsEn l10n,
  required int townLevel,
  required bool enabled,
  bool canMutateViaUi = true,
  Map<String, int> currentBonus = const {},
  Map<String, int> nextBonus = const {},
}) {
  return upgradeTownPayoffGistForTile(
    l10n: l10n,
    game: _game(townLevel: townLevel),
    humanPlayerId: _humanId,
    tileKey: _tile,
    enabled: enabled,
    canMutateViaUi: canMutateViaUi,
    currentBonus: currentBonus,
    nextBonus: nextBonus,
  );
}

void main() {
  final l10n = AppLocalizationsEn();

  test('1→2 gist starts workshops and takes 1 turn (Refs #4747)', () {
    expect(
      upgradeTownPayoffGistLine(l10n: l10n, fromLevel: 1, turns: 1),
      'After this work: town workshops start · Takes 1 turn',
    );
  });

  test('2→3 gist warns pause until level 4 (Refs #4747)', () {
    expect(
      upgradeTownPayoffGistLine(
        l10n: l10n,
        fromLevel: 2,
        turns: 1,
        goodsClause: ' (+1 Lumber)',
      ),
      'After this work: town workshops pause until level 4 (+1 Lumber) · Takes 1 turn',
    );
  });

  test('3→4 gist resumes at double the level-2 rate (Refs #4747)', () {
    expect(
      upgradeTownPayoffGistLine(l10n: l10n, fromLevel: 3, turns: 1),
      'After this work: town workshops resume at double the level-2 rate · Takes 1 turn',
    );
  });

  test('goods clause names at most two display names', () {
    expect(
      upgradeTownPayoffGoodsClause(l10n, const {
        'lumber': 1,
        'fabric': 2,
        'castIron': 3,
      }),
      ' (+3 Cast iron, +2 Fabric)',
    );
  });

  test('empty bonus has no goods clause', () {
    expect(upgradeTownPayoffGoodsClause(l10n, const {}), '');
  });

  test('enabled 1-of-4 gist starts workshops and names next-level goods', () {
    final gist = _gistFor(
      l10n: l10n,
      townLevel: 1,
      enabled: true,
      nextBonus: const {'castIron': 1, 'lumber': 2},
    );
    expect(gist, contains('town workshops start'));
    expect(gist, contains('Takes 1 turn'));
    expect(gist, contains('+2 Lumber'));
    expect(gist, contains('+1 Cast iron'));
    expect(gist, isNot(contains('castIron')));
    expect(gist!.toLowerCase(), isNot(contains('manufacturing bonus')));
  });

  test('enabled 2-of-4 gist pauses using current Town production goods', () {
    final gist = _gistFor(
      l10n: l10n,
      townLevel: 2,
      enabled: true,
      currentBonus: const {'lumber': 1},
      nextBonus: const {'fabric': 9},
    );
    expect(
      gist,
      'After this work: town workshops pause until level 4 (+1 Lumber) · Takes 1 turn',
    );
    expect(gist, isNot(contains('Fabric')));
  });

  test('enabled 3-of-4 gist resumes using next-level goods', () {
    final gist = _gistFor(
      l10n: l10n,
      townLevel: 3,
      enabled: true,
      currentBonus: const {'lumber': 1},
      nextBonus: const {'fabric': 2},
    );
    expect(gist, contains('resume at double the level-2 rate'));
    expect(gist, contains('+2 Fabric'));
    expect(gist, isNot(contains('Lumber')));
  });

  test(
    'assign gist hides when disabled, observe, or town is already 4 of 4',
    () {
      expect(_gistFor(l10n: l10n, townLevel: 2, enabled: false), isNull);
      expect(
        _gistFor(
          l10n: l10n,
          townLevel: 2,
          enabled: true,
          canMutateViaUi: false,
        ),
        isNull,
      );
      expect(_gistFor(l10n: l10n, townLevel: 4, enabled: true), isNull);
    },
  );

  test(
    'empty preview still teaches start/pause/resume without invented goods',
    () {
      for (final level in const [1, 2, 3]) {
        final gist = _gistFor(l10n: l10n, townLevel: level, enabled: true);
        expect(gist, isNotNull);
        expect(gist, contains('Takes 1 turn'));
        expect(gist, isNot(contains('+')));
        expect(gist!.toLowerCase(), isNot(contains('finish')));
        expect(gist.toLowerCase(), isNot(contains('recipe')));
        expect(gist.toLowerCase(), isNot(contains('manufacturing bonus')));
      }
      expect(
        _gistFor(l10n: l10n, townLevel: 1, enabled: true),
        contains('town workshops start'),
      );
      expect(
        _gistFor(l10n: l10n, townLevel: 2, enabled: true),
        contains('pause until level 4'),
      );
      expect(
        _gistFor(l10n: l10n, townLevel: 3, enabled: true),
        contains('resume at double the level-2 rate'),
      );
    },
  );

  test('pending gist is upgrade_town-only (Refs #4747)', () {
    final game = _game(townLevel: 2);
    expect(
      upgradeTownPayoffPendingGistChildren(
        l10n: l10n,
        game: game,
        humanPlayerId: _humanId,
        pendingWork: const WorkOrder(
          unitId: 'u_builder',
          target: kWorkTargetExplore,
          targetTileKey: _tile,
        ),
        readOnly: false,
      ),
      isEmpty,
    );
    expect(
      upgradeTownPayoffPendingGistChildren(
        l10n: l10n,
        game: game,
        humanPlayerId: _humanId,
        pendingWork: const WorkOrder(
          unitId: 'u_builder',
          target: kWorkTargetUpgradeTown,
          targetTileKey: _tile,
        ),
        readOnly: false,
      ),
      hasLength(1),
    );
  });
}
