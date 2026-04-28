import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/ct_debug_console.dart';

final debugConsoleEnabledProvider = Provider<bool>(
  (ref) => kCtDebugConsoleEnabled,
);
