import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef ParserRejectCase = ({String input, String contains});

typedef ParserCreditCase = ({
  String input,
  Type type,
  String? id,
  int? count,
  int? requested,
  int? credited,
});

const parserSpawnCreditRejectCases = <ParserRejectCase>[
  (
    input: '/spawn_civilian explorer nope',
    contains: 'Count must be an integer',
  ),
  (input: '/spawn_civilian explorer 26', contains: 'between 1 and 25'),
  (input: '/add_money abc', contains: 'Amount must be an integer'),
  (input: '/add_money 0', contains: 'at least 1'),
  (input: '/add_worker nobles 1', contains: 'Unknown worker tier'),
  (input: '/add_worker peasants abc', contains: 'Amount must be an integer'),
  (input: '/add_worker peasants 0', contains: 'at least 1'),
  (input: '/add_resource nope 10', contains: 'Unknown commodity id'),
  (input: '/add_resource grain abc', contains: 'Amount must be an integer'),
  (input: '/add_resource grain 0', contains: 'at least 1'),
  (input: '/spawn_regiment nope', contains: 'Unknown regiment type id'),
  (input: '/spawn_ship nope', contains: 'Unknown ship type id'),
  (input: '/spawn_ship carrack 26', contains: 'between 1 and 25'),
];

ParserCreditCase _credit(
  String input,
  Type type, {
  String? id,
  int? count,
  int? requested,
  int? credited,
}) => (
  input: input,
  type: type,
  id: id,
  count: count,
  requested: requested,
  credited: credited,
);

final parserSpawnCreditSuccessCases = <ParserCreditCase>[
  _credit(
    '/spawn_civilian explorer',
    DebugConsoleSpawnCivilianAtCapital,
    id: kUnitTypeExplorer,
    count: 1,
  ),
  _credit(
    '/spawn_civilian rail_builder 2',
    DebugConsoleSpawnCivilianAtCapital,
    id: kUnitTypeRailBuilder,
    count: 2,
  ),
  _credit(
    '/add_money 100',
    DebugConsoleTreasuryCredit,
    requested: 100,
    credited: 100,
  ),
  _credit(
    '/add_money 12000',
    DebugConsoleTreasuryCredit,
    requested: 12000,
    credited: kDebugConsoleMaxTreasuryCreditAmount,
  ),
  _credit(
    '/add_worker PEASANTS 10',
    DebugConsoleWorkerPoolCredit,
    id: 'peasants',
    requested: 10,
  ),
  _credit(
    '/add_worker apprentices 12000',
    DebugConsoleWorkerPoolCredit,
    id: 'apprentices',
    requested: 12000,
    credited: kDebugConsoleMaxTreasuryCreditAmount,
  ),
  _credit(
    '/add_resource grain 500',
    DebugConsoleStockpileCredit,
    id: 'grain',
    requested: 500,
  ),
  _credit(
    '/add_resource castIRON 10',
    DebugConsoleStockpileCredit,
    id: 'castIron',
  ),
  _credit(
    '/add_resource grain 12000',
    DebugConsoleStockpileCredit,
    requested: 12000,
    credited: kDebugConsoleMaxTreasuryCreditAmount,
  ),
  _credit(
    '/spawn_regiment peasant_levies',
    DebugConsoleSpawnRegimentAtCapital,
    id: 'peasant_levies',
    count: 1,
  ),
  _credit(
    '/spawn_ship carrack',
    DebugConsoleSpawnShipAtCapitalHomeFleet,
    id: 'carrack',
    count: 1,
  ),
];

void expectParserCredit(DebugConsoleParseResult result, ParserCreditCase row) {
  expect(result.isError, isFalse, reason: row.input);
  final invocation = result.invocation!;
  expect(invocation.runtimeType, row.type, reason: row.input);
  switch (invocation) {
    case DebugConsoleSpawnCivilianAtCapital(:final unitType, :final count):
      expect(unitType, row.id, reason: row.input);
      expect(count, row.count, reason: row.input);
    case DebugConsoleTreasuryCredit(
      :final requestedAmount,
      :final creditedAmount,
    ):
      expect(requestedAmount, row.requested, reason: row.input);
      expect(creditedAmount, row.credited, reason: row.input);
    case DebugConsoleWorkerPoolCredit(
      :final workerTierId,
      :final requestedAmount,
      :final creditedAmount,
    ):
      expect(workerTierId, row.id, reason: row.input);
      expect(requestedAmount, row.requested, reason: row.input);
      if (row.credited != null) {
        expect(creditedAmount, row.credited, reason: row.input);
      }
    case DebugConsoleStockpileCredit(
      :final commodityId,
      :final requestedAmount,
      :final creditedAmount,
    ):
      if (row.id != null) {
        expect(commodityId, row.id, reason: row.input);
      }
      if (row.requested != null) {
        expect(requestedAmount, row.requested, reason: row.input);
      }
      if (row.credited != null) {
        expect(creditedAmount, row.credited, reason: row.input);
      }
    case DebugConsoleSpawnRegimentAtCapital(
      :final regimentTypeId,
      :final count,
    ):
      expect(regimentTypeId, row.id, reason: row.input);
      expect(count, row.count, reason: row.input);
    case DebugConsoleSpawnShipAtCapitalHomeFleet(
      :final shipTypeId,
      :final count,
    ):
      expect(shipTypeId, row.id, reason: row.input);
      expect(count, row.count, reason: row.input);
    default:
      fail('${row.input}: unexpected ${invocation.runtimeType}');
  }
}
