import 'package:colonizethis_app/features/game/widgets/units/civilian/transport_step_yield_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('raise kind uses transport step raise copy', () {
    const preview = TransportStepYieldPreview(
      commodityId: 'grain',
      currentEffective: 0,
      nextEffective: 1,
      kind: TransportStepYieldKind.raise,
    );
    expect(
      transportStepYieldGistLine(l10n: l10n, preview: preview),
      l10n.provinceOverlay_tileTransportStepYieldRaise(0, 1, 'Grain'),
    );
  });

  test('portOnCoast kind uses port copy', () {
    const preview = TransportStepYieldPreview(
      kind: TransportStepYieldKind.portOnCoast,
      currentEffective: 0,
      nextEffective: 0,
    );
    expect(
      transportStepYieldGistLine(l10n: l10n, preview: preview),
      l10n.provinceOverlay_tileTransportStepPortOnCoast,
    );
  });

  test('disconnected kind uses disconnected copy', () {
    const preview = TransportStepYieldPreview(
      commodityId: 'grain',
      kind: TransportStepYieldKind.disconnected,
      currentEffective: 0,
      nextEffective: 0,
    );
    expect(
      transportStepYieldGistLine(l10n: l10n, preview: preview),
      l10n.provinceOverlay_tileTransportStepYieldDisconnected,
    );
  });
}
