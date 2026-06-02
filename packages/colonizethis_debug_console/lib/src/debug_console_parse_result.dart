import 'debug_console_parsed_invocation.dart';

class DebugConsoleParseResult {
  const DebugConsoleParseResult.success(this.invocation)
    : message = null,
      isError = false;

  const DebugConsoleParseResult.error(this.message)
    : invocation = null,
      isError = true;

  final DebugConsoleParsedInvocation? invocation;
  final String? message;
  final bool isError;
}
