import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef ExecutorSpawnCreditCase = ({
  String input,
  Type eventType,
  String? id,
  int? count,
  int? requested,
  int? credited,
  List<String> messageContains,
});

typedef ExecutorProvinceCase = ({
  String input,
  Type eventType,
  String? regionId,
  String? provinceDisplayName,
  String? fullProvinceId,
  String? target,
  bool? targetIsFullProvinceId,
});

typedef ExecutorDiplomacyCase = ({
  String input,
  bool isError,
  String? factionA,
  String? factionB,
  DebugDiplomacyAction? action,
  List<String> messageContains,
});

ExecutorSpawnCreditCase _sc(
  String input,
  Type eventType, {
  String? id,
  int? count,
  int? requested,
  int? credited,
  List<String> contains = const [],
}) => (
  input: input,
  eventType: eventType,
  id: id,
  count: count,
  requested: requested,
  credited: credited,
  messageContains: contains,
);

final executorSpawnCreditSuccessCases = <ExecutorSpawnCreditCase>[
  _sc(
    '/spawn_civilian builder 3',
    SpawnDebugCivilianAtCapitalEvent,
    id: kUnitTypeBuilder,
    count: 3,
  ),
  _sc(
    '/add_money 500',
    CreditDebugTreasuryEvent,
    requested: 500,
    credited: 500,
    contains: ['500'],
  ),
  _sc(
    '/add_worker journeymen 8',
    CreditDebugWorkerPoolEvent,
    id: 'journeymen',
    requested: 8,
    contains: ['journeymen'],
  ),
  _sc(
    '/add_resource grain 500',
    CreditDebugStockpileCommodityEvent,
    id: 'grain',
    requested: 500,
    contains: ['grain'],
  ),
  _sc(
    '/spawn_regiment peasant_levies 2',
    SpawnDebugRegimentAtCapitalEvent,
    id: 'peasant_levies',
    count: 2,
    contains: ['peasant_levies'],
  ),
  _sc(
    '/spawn_ship carrack 2',
    SpawnDebugShipAtCapitalHomeFleetEvent,
    id: 'carrack',
    count: 2,
    contains: ['carrack'],
  ),
];

final executorClampCases = <ExecutorSpawnCreditCase>[
  _sc(
    '/add_money 20000',
    CreditDebugTreasuryEvent,
    requested: 20000,
    credited: kDebugConsoleMaxTreasuryCreditAmount,
    contains: ['20000', '9999'],
  ),
  _sc(
    '/add_worker masters 20000',
    CreditDebugWorkerPoolEvent,
    id: 'masters',
    requested: 20000,
    contains: ['20000', '9999'],
  ),
  _sc(
    '/add_resource castIron 20000',
    CreditDebugStockpileCommodityEvent,
    id: 'castIron',
    requested: 20000,
    contains: ['20000', '9999'],
  ),
];

const executorProvinceCases = <ExecutorProvinceCase>[
  (
    input: '/flip_province oldWorld New Bordeaux',
    eventType: FlipDebugProvinceOwnershipEvent,
    regionId: 'oldWorld',
    provinceDisplayName: 'New Bordeaux',
    fullProvinceId: null,
    target: null,
    targetIsFullProvinceId: null,
  ),
  (
    input: '/flip_province oldWorld|P1',
    eventType: FlipDebugProvinceOwnershipEvent,
    regionId: null,
    provinceDisplayName: null,
    fullProvinceId: 'oldWorld|P1',
    target: null,
    targetIsFullProvinceId: null,
  ),
  (
    input: '/reveal_province oldWorld|P1',
    eventType: RevealDebugProvinceEvent,
    regionId: null,
    provinceDisplayName: null,
    fullProvinceId: null,
    target: 'oldWorld|P1',
    targetIsFullProvinceId: true,
  ),
];

const executorMutatingTypeCases = <(String, Type)>[
  ('/spawn_civilian explorer', SpawnDebugCivilianAtCapitalEvent),
  ('/add_money 5', CreditDebugTreasuryEvent),
  ('/reveal_province oldWorld|P1', RevealDebugProvinceEvent),
];

const executorDiplomacyCases = <ExecutorDiplomacyCase>[
  (
    input: '/set_diplomacy Ireland war',
    isError: false,
    factionA: null,
    factionB: 'Ireland',
    action: DebugDiplomacyAction.war,
    messageContains: ['war', 'Ireland'],
  ),
  (
    input: '/set_diplomacy England France alliance',
    isError: false,
    factionA: 'England',
    factionB: 'France',
    action: DebugDiplomacyAction.alliance,
    messageContains: ['England', 'France'],
  ),
  (
    input: '/set_diplomacy Ireland befriend',
    isError: true,
    factionA: null,
    factionB: null,
    action: null,
    messageContains: [],
  ),
];

void expectExecutorSpawnCredit(
  DebugConsoleCommandExecutor executor,
  ExecutorSpawnCreditCase row,
) {
  final result = executor.executeRaw(rawInput: row.input, humanPlayerId: 'p1');
  expect(result.isError, isFalse, reason: row.input);
  final event = result.events.single;
  expect(event.runtimeType, row.eventType, reason: row.input);
  switch (event) {
    case SpawnDebugCivilianAtCapitalEvent(
      :final humanPlayerId,
      :final unitType,
      :final count,
    ):
      expect(humanPlayerId, 'p1', reason: row.input);
      expect(unitType, row.id, reason: row.input);
      expect(count, row.count, reason: row.input);
    case CreditDebugTreasuryEvent(
      :final requestedAmount,
      :final creditedAmount,
    ):
      expect(requestedAmount, row.requested, reason: row.input);
      expect(creditedAmount, row.credited, reason: row.input);
    case CreditDebugWorkerPoolEvent(
      :final workerTierId,
      :final requestedAmount,
    ):
      expect(workerTierId, row.id, reason: row.input);
      expect(requestedAmount, row.requested, reason: row.input);
    case CreditDebugStockpileCommodityEvent(
      :final commodityId,
      :final requestedAmount,
    ):
      expect(commodityId, row.id, reason: row.input);
      expect(requestedAmount, row.requested, reason: row.input);
    case SpawnDebugRegimentAtCapitalEvent(:final regimentTypeId, :final count):
      expect(regimentTypeId, row.id, reason: row.input);
      expect(count, row.count, reason: row.input);
    case SpawnDebugShipAtCapitalHomeFleetEvent(:final shipTypeId, :final count):
      expect(shipTypeId, row.id, reason: row.input);
      expect(count, row.count, reason: row.input);
    default:
      fail('${row.input}: unexpected ${event.runtimeType}');
  }
  for (final fragment in row.messageContains) {
    expect(result.message, contains(fragment), reason: row.input);
  }
}
