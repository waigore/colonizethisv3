import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/turn_resolution_runner.dart';

final turnResolutionRunnerProvider = Provider<TurnResolutionRunner>(
  (ref) => TurnResolutionRunner(),
);
