// Unit tests for Victory province origin inspect copy. SPEC/ui/victory-panel.md.

import 'package:colonizethis_app/features/game/screens/victory/victory_province_origin.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'panel_fixtures/core.dart';

void main() {
  group('victoryProvinceInspectLabel', () {
    test('reports original owner when still held', () {
      final game = buildPanelTestGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
            originalOwnerId: 'gp1',
            displayName: 'London',
          ),
        ],
      );
      final label = victoryProvinceInspectLabel(
        game,
        game.worldState.oldWorld.provinces.single,
      );
      expect(label, contains('still held by original owner'));
      expect(label, contains('London'));
    });

    test('reports capture from founding owner', () {
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp2',
            originalOwnerId: 'gp1',
            displayName: 'Yorkshire',
          ),
        ],
      );
      final label = victoryProvinceInspectLabel(
        game,
        game.worldState.oldWorld.provinces.single,
      );
      expect(label, contains('captured from England'));
      expect(label, contains('now France'));
    });

    test('graceful unknown when originalOwnerId missing', () {
      final game = buildPanelTestGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ],
      );
      final label = victoryProvinceInspectLabel(
        game,
        game.worldState.oldWorld.provinces.single,
      );
      expect(label, 'Origin unavailable for this province.');
    });
  });
}
