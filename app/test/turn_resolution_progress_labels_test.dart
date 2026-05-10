import 'package:colonizethis_app/features/game/flame/turn_resolution_progress_labels.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('turnResolutionProgressPhaseLabel covers worker and resolver phases', () {
    expect(
      turnResolutionProgressPhaseLabel('aiPlanning'),
      'Planning AI orders...',
    );
    expect(turnResolutionProgressPhaseLabel('orders'), isNotEmpty);
    expect(
      turnResolutionProgressPhaseLabel('endOfTurn'),
      'Finalizing turn...',
    );
    expect(turnResolutionProgressPhaseLabel('unknownPhase'), 'Resolving turn...');
  });
}
