import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef ParserCommandCase = ({
  String input,
  bool isError,
  Type? type,
  String? messageContains,
  String? messageEquals,
  String? id,
  String? factionA,
  String? factionB,
  DebugDiplomacyAction? action,
  bool? targetIsFullProvinceId,
});

ParserCommandCase _cmd(
  String input, {
  bool isError = false,
  Type? type,
  String? messageContains,
  String? messageEquals,
  String? id,
  String? factionA,
  String? factionB,
  DebugDiplomacyAction? action,
  bool? targetIsFullProvinceId,
}) => (
  input: input,
  isError: isError,
  type: type,
  messageContains: messageContains,
  messageEquals: messageEquals,
  id: id,
  factionA: factionA,
  factionB: factionB,
  action: action,
  targetIsFullProvinceId: targetIsFullProvinceId,
);

final parserLeftoverCommandCases = <ParserCommandCase>[
  _cmd('/unknown', isError: true, messageContains: 'Unknown command'),
  _cmd(
    '/flip_province oldWorld|P1',
    type: DebugConsoleFlipProvince,
    id: 'oldWorld|P1',
  ),
  _cmd(
    '/reveal_province oldWorld|P1',
    type: DebugConsoleRevealProvince,
    id: 'oldWorld|P1',
    targetIsFullProvinceId: true,
  ),
  _cmd(
    '/reveal_province New Bordeaux',
    type: DebugConsoleRevealProvince,
    id: 'New Bordeaux',
    targetIsFullProvinceId: false,
  ),
  _cmd(
    '/reveal_province P1',
    isError: true,
    messageContains: 'Use full province id format',
  ),
  _cmd('/get_tile_basic_info', type: DebugConsoleGetTileBasicInfo),
  _cmd(
    '/get_tile_basic_info extra',
    isError: true,
    messageEquals: 'Usage: /get_tile_basic_info',
  ),
  _cmd('/list_players', type: DebugConsoleListPlayers),
  _cmd(
    '/list_players foo',
    isError: true,
    messageEquals: 'Usage: /list_players',
  ),
  _cmd('/observe', type: DebugConsoleSetObserveGlobal),
  _cmd('/observe off', type: DebugConsoleSetObserveOff),
  _cmd('/observe France', type: DebugConsoleSetObservePlayer, id: 'France'),
  _cmd(
    '/set_diplomacy Ireland war',
    type: DebugConsoleSetDiplomacy,
    factionB: 'Ireland',
    action: DebugDiplomacyAction.war,
  ),
  _cmd(
    '/set_diplomacy England France alliance',
    type: DebugConsoleSetDiplomacy,
    factionA: 'England',
    factionB: 'France',
    action: DebugDiplomacyAction.alliance,
  ),
  _cmd(
    '/set_diplomacy "Zulu Kingdom" war',
    type: DebugConsoleSetDiplomacy,
    factionB: 'Zulu Kingdom',
    action: DebugDiplomacyAction.war,
  ),
  _cmd(
    '/set_diplomacy England France no_alliance',
    type: DebugConsoleSetDiplomacy,
    factionA: 'England',
    factionB: 'France',
    action: DebugDiplomacyAction.noAlliance,
  ),
  _cmd(
    '/set_diplomacy Ireland JOIN_EMPIRE',
    type: DebugConsoleSetDiplomacy,
    factionB: 'Ireland',
    action: DebugDiplomacyAction.joinEmpire,
  ),
  _cmd(
    '/set_diplomacy Ireland befriend',
    isError: true,
    messageContains: 'Unknown diplomacy action',
  ),
  _cmd(
    '/set_diplomacy Ireland',
    isError: true,
    messageContains: 'Usage: /set_diplomacy',
  ),
  _cmd(
    '/set_diplomacy A B C war',
    isError: true,
    messageContains: 'Usage: /set_diplomacy',
  ),
];

void expectParserLeftover(
  DebugConsoleParseResult result,
  ParserCommandCase row,
) {
  expect(result.isError, row.isError, reason: row.input);
  if (row.messageContains != null) {
    expect(result.message, contains(row.messageContains!), reason: row.input);
  }
  if (row.messageEquals != null) {
    expect(result.message, row.messageEquals, reason: row.input);
  }
  if (row.isError) {
    return;
  }
  final invocation = result.invocation!;
  expect(invocation.runtimeType, row.type, reason: row.input);
  switch (invocation) {
    case DebugConsoleFlipProvince(
      :final fullProvinceId,
      :final regionId,
      :final provinceDisplayName,
    ):
      expect(fullProvinceId, row.id, reason: row.input);
      expect(regionId, isNull, reason: row.input);
      expect(provinceDisplayName, isNull, reason: row.input);
    case DebugConsoleRevealProvince(
      :final target,
      :final targetIsFullProvinceId,
    ):
      expect(target, row.id, reason: row.input);
      expect(
        targetIsFullProvinceId,
        row.targetIsFullProvinceId,
        reason: row.input,
      );
    case DebugConsoleSetObservePlayer(:final target):
      expect(target, row.id, reason: row.input);
    case DebugConsoleSetDiplomacy(
      :final factionA,
      :final factionB,
      :final action,
    ):
      expect(factionA, row.factionA, reason: row.input);
      expect(factionB, row.factionB, reason: row.input);
      expect(action, row.action, reason: row.input);
    default:
      break;
  }
}
