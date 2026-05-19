import 'debug_console_parse_result.dart';
import 'debug_console_parsed_invocation.dart';

final RegExp debugConsoleLocalProvinceIdPattern = RegExp(r'^P[0-9]+$');

DebugConsoleParseResult parseFlipProvinceCommand(List<String> tokens) {
  if (tokens.length == 2) {
    final fullProvinceId = tokens[1].trim();
    if (!debugConsoleLooksLikePrefixedProvinceId(fullProvinceId)) {
      return const DebugConsoleParseResult.error(
        'Usage: /flip_province <regionId> <province_display_name> OR /flip_province <regionId|localId>',
      );
    }
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.flipProvince(
        fullProvinceId: fullProvinceId,
      ),
    );
  }
  if (tokens.length < 3) {
    return const DebugConsoleParseResult.error(
      'Usage: /flip_province <regionId> <province_display_name> OR /flip_province <regionId|localId>',
    );
  }
  final regionId = tokens[1].trim();
  if (regionId.isEmpty) {
    return const DebugConsoleParseResult.error('Region id must not be empty.');
  }
  final provinceDisplayName = tokens.sublist(2).join(' ').trim();
  if (provinceDisplayName.isEmpty) {
    return const DebugConsoleParseResult.error(
      'Province display name must not be empty.',
    );
  }
  return DebugConsoleParseResult.success(
    DebugConsoleParsedInvocation.flipProvince(
      regionId: regionId,
      provinceDisplayName: provinceDisplayName,
    ),
  );
}

DebugConsoleParseResult parseRevealProvinceCommand(List<String> tokens) {
  if (tokens.length < 2) {
    return const DebugConsoleParseResult.error(
      'Usage: /reveal_province <regionId|localId | province_display_name>',
    );
  }
  final target = tokens.sublist(1).join(' ').trim();
  if (target.isEmpty) {
    return const DebugConsoleParseResult.error(
      'Usage: /reveal_province <regionId|localId | province_display_name>',
    );
  }
  if (debugConsoleLocalProvinceIdPattern.hasMatch(target)) {
    return const DebugConsoleParseResult.error(
      'Use full province id format: regionId|localId',
    );
  }
  final targetIsFullProvinceId = debugConsoleLooksLikePrefixedProvinceId(target);
  return DebugConsoleParseResult.success(
    DebugConsoleParsedInvocation.revealProvince(
      target: target,
      targetIsFullProvinceId: targetIsFullProvinceId,
    ),
  );
}

DebugConsoleParseResult parseObserveCommand(List<String> tokens) {
  if (tokens.length == 1) {
    return const DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.setObserveGlobal(),
    );
  }
  if (tokens.length == 2 && tokens[1].toLowerCase() == 'off') {
    return const DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.setObserveOff(),
    );
  }
  if (tokens.length >= 2) {
    final target = tokens.sublist(1).join(' ');
    return DebugConsoleParseResult.success(
      DebugConsoleParsedInvocation.setObservePlayer(target: target),
    );
  }
  return const DebugConsoleParseResult.error(
    'Usage: /observe | /observe off | /observe <player_id | display_name>',
  );
}

bool debugConsoleLooksLikePrefixedProvinceId(String value) {
  final separator = value.indexOf('|');
  if (separator <= 0 || separator == value.length - 1) {
    return false;
  }
  return true;
}
