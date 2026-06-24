import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_console_parse_result.dart';
import 'debug_console_parsed_invocation.dart';

/// Matches a double-quoted segment (kept whole) or a run of non-whitespace.
final RegExp _debugConsoleQuoteAwareToken = RegExp(r'"[^"]*"|\S+');

/// Parses `/set_diplomacy` from the trimmed raw input.
///
/// Two accepted forms (the last token is always the action keyword):
/// - `/set_diplomacy <faction_b> <action>` — current human player vs `faction_b`.
/// - `/set_diplomacy <faction_a> <faction_b> <action>` — two explicit factions.
///
/// Faction identifiers may contain spaces when wrapped in double quotes
/// (for example `/set_diplomacy "Zulu Kingdom" war`). Faction resolution and
/// state validation are performed by the app apply layer; the parser only
/// validates the command shape and the action keyword.
DebugConsoleParseResult parseSetDiplomacyCommand(String trimmedInput) {
  final tokens = _tokenizeRespectingQuotes(trimmedInput);
  // tokens[0] is the command verb; arguments follow.
  final args = tokens.length > 1 ? tokens.sublist(1) : const <String>[];
  if (args.length < 2 || args.length > 3) {
    return _usageError();
  }

  final action = DebugDiplomacyActionTokens.fromKeyword(args.last);
  if (action == null) {
    final supported = DebugDiplomacyActionTokens.sortedKeywords.join(', ');
    return DebugConsoleParseResult.error(
      'Unknown diplomacy action: ${args.last}. Supported actions: $supported.',
    );
  }

  if (args.length == 2) {
    final factionB = args[0].trim();
    if (factionB.isEmpty) {
      return _usageError();
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.setDiplomacy(
        factionB: factionB,
        action: action,
      ),
    );
  }

  final factionA = args[0].trim();
  final factionB = args[1].trim();
  if (factionA.isEmpty || factionB.isEmpty) {
    return _usageError();
  }
  return DebugConsoleParseResult.success(
    DebugConsoleParsedInvocation.setDiplomacy(
      factionA: factionA,
      factionB: factionB,
      action: action,
    ),
  );
}

DebugConsoleParseResult _usageError() {
  final supported = DebugDiplomacyActionTokens.sortedKeywords.join(', ');
  return DebugConsoleParseResult.error(
    'Usage: /set_diplomacy <faction> <action> OR '
    '/set_diplomacy <faction_a> <faction_b> <action>. '
    'Supported actions: $supported.',
  );
}

/// Splits [input] on whitespace while keeping double-quoted segments intact and
/// stripping the surrounding quotes (so `"Zulu Kingdom"` becomes one token).
List<String> _tokenizeRespectingQuotes(String input) {
  return _debugConsoleQuoteAwareToken.allMatches(input).map((match) {
    final token = match.group(0)!;
    if (token.length >= 2 && token.startsWith('"') && token.endsWith('"')) {
      return token.substring(1, token.length - 1);
    }
    return token;
  }).toList();
}
