/// Test-only probe for order-suggestion validation call volume (Refs #2133).
class OrderSuggestionAcceptProbe {
  static bool enabled = false;
  static int count = 0;

  static void reset() {
    count = 0;
  }

  static void bump() {
    if (enabled) {
      count++;
    }
  }
}
