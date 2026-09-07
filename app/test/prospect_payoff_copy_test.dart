import 'package:colonizethis_app/features/game/widgets/units/civilian/prospect_payoff_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

Game _prospectPayoffGame() {
  const humanId = 'gp1';
  const p1 = 'oldWorld|p1';
  const tile = 'oldWorld|p1|0|0';
  return Game(
    id: 'g_prospect_payoff',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: 'oldWorld', ownerId: humanId),
        ],
        units: [
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: humanId,
            locationProvinceId: p1,
            tileKey: tile,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          p1: [tile],
        },
      },
    ),
    players: const [Player(id: humanId, displayName: 'Human', isHuman: true)],
    minorNations: const [],
    tribes: const [],
  );
}

void main() {
  final l10n = AppLocalizationsEn();
  const tile = 'oldWorld|p1|0|0';

  test('1-turn Prospect gist uses mineral-known clause (Refs #4741)', () {
    final game = _prospectPayoffGame();
    final turns = previewTotalTurnsForPendingWorkOrder(
      game: game,
      unit: game.worldState.oldWorld.units.first,
      order: const WorkOrder(
        unitId: 'u_explorer',
        target: kWorkTargetProspect,
        targetTileKey: tile,
      ),
    );
    expect(
      prospectPayoffGistForTile(
        l10n: l10n,
        game: game,
        tileKey: tile,
        enabled: true,
      ),
      'After this work: any mineral on this tile becomes known · Takes 1 turn',
    );
    expect(turns, 1);
  });

  test('Prospect gist hides when disabled or observe (Refs #4741)', () {
    final game = _prospectPayoffGame();
    expect(
      prospectPayoffGistForTile(
        l10n: l10n,
        game: game,
        tileKey: tile,
        enabled: false,
      ),
      isNull,
    );
    expect(
      prospectPayoffGistForTile(
        l10n: l10n,
        game: game,
        tileKey: tile,
        enabled: true,
        canMutateViaUi: false,
      ),
      isNull,
    );
  });

  test('Prospect gist hides without a land-province tile (Refs #4741)', () {
    expect(
      prospectPayoffGistForTile(
        l10n: l10n,
        game: _prospectPayoffGame(),
        tileKey: '',
        enabled: true,
      ),
      isNull,
    );
  });

  test('Prospect gist does not name commodities or claim a deposit', () {
    final gist = prospectPayoffGistLine(l10n: l10n, turns: 1);
    expect(gist, isNot(contains('iron')));
    expect(gist, isNot(contains('immediately')));
    expect(gist, isNot(contains('definitely')));
    expect(gist, isNot(contains(kWorkTargetProspect)));
  });

  test('Prospect gist line helper matches l10n pluralization', () {
    expect(
      prospectPayoffGistLine(l10n: l10n, turns: 1),
      'After this work: any mineral on this tile becomes known · Takes 1 turn',
    );
    expect(
      prospectPayoffGistLine(l10n: l10n, turns: 2),
      'After this work: any mineral on this tile becomes known · Takes 2 turns',
    );
  });

  test('pending and shortcut Prospect gists hide in observe (Refs #4741)', () {
    final game = _prospectPayoffGame();
    const pending = WorkOrder(
      unitId: 'u_explorer',
      target: kWorkTargetProspect,
      targetTileKey: tile,
    );
    expect(
      prospectPayoffPendingGistChildren(l10n, game, pending, true),
      isEmpty,
    );
    expect(prospectShortcutGist(l10n, game, tile, true), isNull);
    expect(
      prospectPayoffPendingGistChildren(l10n, game, pending, false),
      isNotEmpty,
    );
    expect(prospectShortcutGist(l10n, game, tile, false), isNotNull);
  });
}
