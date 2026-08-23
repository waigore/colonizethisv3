import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_test/test.dart';
import 'player_view_helpers_visibility_cases.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Pure projection helpers in `lib/src/world/player_view.dart`.
/// SPEC/game/fog-and-exploration.md and SPEC/program/player-view.md.
PlayerView _view({
  String playerId = 'p1',
  Map<String, Unit> ownUnitsById = const {},
  Map<String, Province> provincesById = const {},
  Map<String, VisibilityLevel> visibilityByTile = const {},
  Set<String> prospectedTiles = const {},
  Map<String, DiplomacyRelation> diplomacyByOtherId = const {},
}) {
  return PlayerView(
    playerId: playerId,
    player: Player(id: playerId, displayName: 'P', isHuman: true),
    ownUnitsById: ownUnitsById,
    provincesById: provincesById,
    visibilityByTile: visibilityByTile,
    prospectedTiles: prospectedTiles,
    diplomacyByOtherId: diplomacyByOtherId,
  );
}

void main() {
  group('resourceIdVisibleToPlayer', () {
    test('hidden when there is no authoritative resource', () {
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: null,
          visibility: VisibilityLevel.fullyVisible,
          tileProspectedByPlayer: true,
        ),
        isNull,
      );
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: '',
          visibility: VisibilityLevel.fullyVisible,
          tileProspectedByPlayer: true,
        ),
        isNull,
      );
    });

    test('hidden for unknown tiles regardless of prospection', () {
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: 'food',
          visibility: VisibilityLevel.unknown,
          tileProspectedByPlayer: true,
        ),
        isNull,
      );
    });

    test('surface resources are visible when fogged without prospecting', () {
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: 'food',
          visibility: VisibilityLevel.fogged,
          tileProspectedByPlayer: false,
        ),
        'food',
      );
    });

    test(
      'prospect-required resources stay hidden until prospected (fogged)',
      () {
        expect(
          resourceIdVisibleToPlayer(
            authoritativeResourceId: 'gold',
            visibility: VisibilityLevel.fogged,
            tileProspectedByPlayer: false,
          ),
          isNull,
        );
        expect(
          resourceIdVisibleToPlayer(
            authoritativeResourceId: 'gold',
            visibility: VisibilityLevel.fogged,
            tileProspectedByPlayer: true,
          ),
          'gold',
        );
      },
    );

    test('prospect-required resources stay hidden until prospected (full)', () {
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: 'iron',
          visibility: VisibilityLevel.fullyVisible,
          tileProspectedByPlayer: false,
        ),
        isNull,
      );
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: 'iron',
          visibility: VisibilityLevel.fullyVisible,
          tileProspectedByPlayer: true,
        ),
        'iron',
      );
    });

    test('surface resources are visible when fully visible', () {
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: 'wheat',
          visibility: VisibilityLevel.fullyVisible,
          tileProspectedByPlayer: false,
        ),
        'wheat',
      );
    });
  });

  group('resourceIdVisibleInPlayerView', () {
    test('reads visibility and prospection from the view', () {
      final view = _view(
        visibilityByTile: const {'t1': VisibilityLevel.fogged},
        prospectedTiles: const {'t1'},
      );
      expect(resourceIdVisibleInPlayerView(view, 't1', 'gold'), 'gold');
      // Unknown tile (absent from the map) hides the resource.
      expect(resourceIdVisibleInPlayerView(view, 't2', 'gold'), isNull);
    });
  });

  registerPlayerViewHelpersVisibilityCases();
}
