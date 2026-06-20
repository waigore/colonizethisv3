import 'package_log_prefix.dart';
import 'src/ct_logger.dart';
import 'src/package_domain_logger.dart';

export 'src/ct_logger.dart' show CtLogger;

CtLogger packageLogger([String? subPrefix]) =>
    domainPackageLogger(kPackageLogPrefix, subPrefix);
