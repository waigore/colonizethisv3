import 'package_log_prefix.dart';
export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;
import 'package:colonizethis_logger/colonizethis_logger.dart';

CtLogger packageLogger([String? subPrefix]) {
  if (subPrefix == null || subPrefix.isEmpty) {
    return CtLogger(kPackageLogPrefix);
  }
  return CtLogger('$kPackageLogPrefix.$subPrefix');
}
