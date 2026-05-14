import 'package_log_prefix.dart';
export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;
import 'package:colonizethis_logger/colonizethis_logger.dart';

CtLogger packageLogger([String? subPrefix]) {
  if (subPrefix == null || subPrefix.isEmpty) {
    return CtLogger(kPackageLogPrefix);
  }
  return CtLogger('$kPackageLogPrefix.$subPrefix');
}

/// Shared package-level [CtLogger] for `colonizethis_logic` source files.
///
/// Every `lib/src/**/*.dart` file that previously declared a private
/// `final _log = packageLogger();` should import and reuse [logicLog] instead.
/// Named module loggers that keep the default `logic:` prefix should alias
/// [logicLog] rather than calling [packageLogger] again (Refs #2391 AC5).
/// Sub-prefixed loggers (for example `order_suggestion`) still use [packageLogger].
final logicLog = packageLogger();
