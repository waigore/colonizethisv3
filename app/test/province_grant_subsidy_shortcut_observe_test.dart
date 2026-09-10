// Pins observe / canMutateViaUi hide for MAP20001 Grant/Subsidy (Refs #4761).

import 'package:colonizethis_app/features/game/flame/map_state/game_map_area_province_action_states_grant_subsidy.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_factory_overlay.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  const ProvinceGrantSubsidyActionState shown = (
    showControl: true,
    enabled: true,
    pending: false,
    ownerId: 'minor1',
    rejectionReason: null,
  );

  test('observe mode hides Grant Aid and Set Subsidy', () {
    final props = bindProvinceOverlayGrantSubsidyProps(
      canMutateViaUi: false,
      grantAidState: shown,
      setSubsidyState: shown,
    );
    expect(props.showGrantAid, isFalse);
    expect(props.showSetSubsidy, isFalse);
    expect(props.grantAidEnabled, isFalse);
    expect(props.setSubsidyEnabled, isFalse);
  });

  test('mutate mode keeps shown Grant Aid and Set Subsidy', () {
    final props = bindProvinceOverlayGrantSubsidyProps(
      canMutateViaUi: true,
      grantAidState: shown,
      setSubsidyState: shown,
    );
    expect(props.showGrantAid, isTrue);
    expect(props.showSetSubsidy, isTrue);
    expect(props.grantAidEnabled, isTrue);
    expect(props.setSubsidyEnabled, isTrue);
  });
}
