import 'package_log_prefix.dart';
export 'src/ct_logger.dart' show CtLogger;
import 'src/ct_logger.dart';

CtLogger packageLogger([String? subPrefix]) {
  if (subPrefix == null || subPrefix.isEmpty) {
    return CtLogger(kPackageLogPrefix);
  }
  return CtLogger('$kPackageLogPrefix.$subPrefix');
}
