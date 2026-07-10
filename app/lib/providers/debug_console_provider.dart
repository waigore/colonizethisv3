import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_fixtures/config/ct_debug_console.dart';

final debugConsoleEnabledProvider = Provider<bool>(
  (ref) => kCtDebugConsoleEnabled,
);
