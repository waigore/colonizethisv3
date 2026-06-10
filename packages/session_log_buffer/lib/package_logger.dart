import 'package:colonizethis_logger/colonizethis_logger.dart';

import 'package_log_prefix.dart';

export 'package:colonizethis_logger/colonizethis_logger.dart' show CtLogger;

CtLogger packageLogger([String? subPrefix]) =>
    domainPackageLogger(kPackageLogPrefix, subPrefix);
