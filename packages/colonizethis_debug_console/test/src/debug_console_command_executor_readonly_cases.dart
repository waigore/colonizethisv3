import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef ExecutorReadOnlyCase = ({
  String input,
  DebugConsoleReadOnlyContext? context,
  bool isError,
  String? messageEquals,
  List<String> messageContains,
  String? startsWith,
  (String earlier, String later)? idOrder,
});

typedef ExecutorObserveCase = ({
  String input,
  DebugConsoleReadOnlyContext? context,
  bool isError,
  Type? eventType,
  String? targetPlayerId,
  String? messageContains,
});

const _ann = DebugConsolePlayerSnapshot(
  id: 'a',
  displayName: 'Ann',
  isHuman: true,
  capitalProvinceId: 'r|P2',
);
const _zed = DebugConsolePlayerSnapshot(
  id: 'z',
  displayName: 'Zed',
  isHuman: false,
  capitalProvinceId: 'r|P1',
);
const _blankName = DebugConsolePlayerSnapshot(
  id: 'p_x',
  displayName: '   ',
  isHuman: true,
);
const _france = DebugConsolePlayerSnapshot(
  id: 'gp2',
  displayName: 'France',
  isHuman: false,
  capitalProvinceId: 'oldWorld|P1',
);
const _eliminated = DebugConsolePlayerSnapshot(
  id: 'gp3',
  displayName: 'Eliminated',
  isHuman: false,
);

final executorGetTileCases = <ExecutorReadOnlyCase>[
  (
    input: '/get_tile_basic_info',
    context: const DebugConsoleReadOnlyContext(
      selectedTileKey: 'oldWorld|P12|34|21',
    ),
    isError: false,
    messageEquals: 'tile_id: oldWorld|P12|34|21\nprovince_id: oldWorld|P12',
    messageContains: const [],
    startsWith: null,
    idOrder: null,
  ),
  (
    input: '/get_tile_basic_info',
    context: null,
    isError: true,
    messageEquals: 'No tile is selected.',
    messageContains: const [],
    startsWith: null,
    idOrder: null,
  ),
  (
    input: '/get_tile_basic_info',
    context: const DebugConsoleReadOnlyContext(selectedTileKey: 'oldWorld|P12'),
    isError: true,
    messageEquals: 'Selected tile key is invalid.',
    messageContains: const [],
    startsWith: null,
    idOrder: null,
  ),
];

final executorListPlayersCases = <ExecutorReadOnlyCase>[
  (
    input: '/list_players',
    context: DebugConsoleReadOnlyContext(players: const [_zed, _ann]),
    isError: false,
    messageEquals: null,
    messageContains: const [
      'player_id: a',
      'display_name: Ann',
      'type: human',
      'eliminated: false',
      'player_id: z',
      'display_name: Zed',
      'type: ai',
    ],
    startsWith: 'players_count: 2',
    idOrder: ('player_id: a', 'player_id: z'),
  ),
  (
    input: '/list_players',
    context: const DebugConsoleReadOnlyContext(players: [_blankName]),
    isError: false,
    messageEquals: null,
    messageContains: const ['display_name: p_x', 'eliminated: true'],
    startsWith: null,
    idOrder: null,
  ),
  (
    input: '/list_players',
    context: null,
    isError: true,
    messageEquals: 'Player list is unavailable.',
    messageContains: const [],
    startsWith: null,
    idOrder: null,
  ),
  (
    input: '/list_players',
    context: const DebugConsoleReadOnlyContext(selectedTileKey: 'x|y|0|0'),
    isError: true,
    messageEquals: 'Player list is unavailable.',
    messageContains: const [],
    startsWith: null,
    idOrder: null,
  ),
];

final executorObserveCases = <ExecutorObserveCase>[
  (
    input: '/observe',
    context: null,
    isError: false,
    eventType: SetObserveModeGlobalEvent,
    targetPlayerId: null,
    messageContains: null,
  ),
  (
    input: '/observe France',
    context: DebugConsoleReadOnlyContext(players: const [_france]),
    isError: false,
    eventType: SetObserveModePlayerEvent,
    targetPlayerId: 'gp2',
    messageContains: null,
  ),
  (
    input: '/observe gp3',
    context: DebugConsoleReadOnlyContext(players: const [_eliminated]),
    isError: true,
    eventType: null,
    targetPlayerId: null,
    messageContains: 'eliminated',
  ),
  (
    input: '/observe missing',
    context: const DebugConsoleReadOnlyContext(players: []),
    isError: true,
    eventType: null,
    targetPlayerId: null,
    messageContains: null,
  ),
];

void expectExecutorReadOnly(
  DebugConsoleCommandExecutor executor,
  ExecutorReadOnlyCase row,
) {
  final result = executor.executeRaw(
    rawInput: row.input,
    humanPlayerId: 'p1',
    readOnlyContext: row.context,
  );
  expect(result.isError, row.isError, reason: row.input);
  expect(result.events, isEmpty, reason: row.input);
  if (row.messageEquals != null) {
    expect(result.message, row.messageEquals, reason: row.input);
  }
  if (row.startsWith != null) {
    expect(result.message, startsWith(row.startsWith!), reason: row.input);
  }
  for (final fragment in row.messageContains) {
    expect(result.message, contains(fragment), reason: row.input);
  }
  final order = row.idOrder;
  if (order != null) {
    expect(
      result.message.indexOf(order.$1),
      lessThan(result.message.indexOf(order.$2)),
      reason: row.input,
    );
  }
}

void expectExecutorObserve(
  DebugConsoleCommandExecutor executor,
  ExecutorObserveCase row,
) {
  final result = executor.executeRaw(
    rawInput: row.input,
    humanPlayerId: 'p1',
    readOnlyContext: row.context,
  );
  expect(result.isError, row.isError, reason: row.input);
  if (row.isError) {
    expect(result.events, isEmpty, reason: row.input);
  } else {
    expect(result.events.single.runtimeType, row.eventType, reason: row.input);
    if (row.targetPlayerId != null) {
      final event = result.events.single as SetObserveModePlayerEvent;
      expect(event.targetPlayerId, row.targetPlayerId, reason: row.input);
    }
  }
  if (row.messageContains != null) {
    expect(result.message, contains(row.messageContains!), reason: row.input);
  }
}
