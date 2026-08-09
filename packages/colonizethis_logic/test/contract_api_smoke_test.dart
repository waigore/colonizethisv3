// Narrow contract export smoke (Refs #4090 Slice E / AC4).
// These libraries are export-only; smoke asserts the barrels resolve symbols
// used by AI / order-suggestion / debug-console consumers.
import 'package:colonizethis_logic/ai_api.dart' as ai_api;
import 'package:colonizethis_logic/debug_console_api.dart' as debug_api;
import 'package:colonizethis_logic/order_suggestion_api.dart' as order_api;
import 'package:colonizethis_test/test.dart';

void main() {
  group('ai_api contract smoke', () {
    test('exports PlayerView and buildPlayerView', () {
      expect(ai_api.buildPlayerView, isA<Function>());
      expect(ai_api.PlayerView, isNotNull);
    });
  });

  group('order_suggestion_api contract smoke', () {
    test('exports DefaultOrderSuggestionAPI and TradeOrderSuggester', () {
      expect(order_api.DefaultOrderSuggestionAPI, isNotNull);
      expect(order_api.TradeOrderSuggester, isNotNull);
    });
  });

  group('debug_console_api contract smoke', () {
    test('exports sorted commodity and unit-type helpers', () {
      expect(debug_api.debugConsoleSupportedCommodityIdsSorted, isNotEmpty);
      expect(debug_api.kUnitTypeExplorer, isA<String>());
    });
  });
}
