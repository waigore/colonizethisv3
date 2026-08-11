// --- Test-only instrumentation (Refs #2237 AC2) ---
bool _trackValidatePlayerOrdersWithContextInvocationsForTests = false;
int _validatePlayerOrdersWithContextInvocationCountForTests = 0;

/// Test hook: when enabled, counts every call to [OrderEngine.validatePlayerOrdersWithContext].
void setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(
  bool enabled,
) {
  _trackValidatePlayerOrdersWithContextInvocationsForTests = enabled;
  _validatePlayerOrdersWithContextInvocationCountForTests = 0;
}

/// Test hook: invocations counted while tracking is enabled (Refs #2237).
int get orderEngineValidatePlayerOrdersWithContextInvocationCountForTests =>
    _validatePlayerOrdersWithContextInvocationCountForTests;

void bumpOrderEngineValidatePlayerOrdersWithContextInvocationIfTracking() {
  if (_trackValidatePlayerOrdersWithContextInvocationsForTests) {
    _validatePlayerOrdersWithContextInvocationCountForTests++;
  }
}
