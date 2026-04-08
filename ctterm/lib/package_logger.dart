import 'package_log_prefix.dart';
import 'package:ctterm/package_logger.dart';

CtLogger packageLogger([String? subPrefix]) {
  if (subPrefix == null || subPrefix.isEmpty) {
    return CtLogger(kPackageLogPrefix);
  }
  return CtLogger('$kPackageLogPrefix.$subPrefix');
}
