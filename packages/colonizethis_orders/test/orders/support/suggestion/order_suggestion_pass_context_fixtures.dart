// Shared fixtures for order suggestion pass context scenarios (Refs #3949
// wave 3, #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const orderSuggestionPassContextTopology = MapTopology(nodes: [], edges: []);

const orderSuggestionPassContextGp1Id = 'gp1';
const orderSuggestionPassContextGp2Id = 'gp2';

Game orderSuggestionPassContextOwnedProvincesGame() =>
    ordersTwoProvinceOwnedGame(
      id: 'g-owned',
      prefixedIds: false,
      players: const [
        Player(
          id: orderSuggestionPassContextGp1Id,
          displayName: 'P1',
          isHuman: true,
        ),
        Player(
          id: orderSuggestionPassContextGp2Id,
          displayName: 'P2',
          isHuman: true,
        ),
      ],
    );
