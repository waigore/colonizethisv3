// Adaptive poll ramps, [E2ePerfLog], and wait helpers — topic-split aggregator
// (Refs #4598 Slice A). Implementations stay in sibling libraries so the two
// ramp families (25→100 vs 25→500) remain separable.
export 'e2e_test_shared_adaptive_polling_core.dart';
export 'e2e_test_shared_adaptive_polling_waits.dart';
