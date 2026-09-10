import 'package:flutter/foundation.dart';

/// MAP20001 Political **Grant Aid** / **Set Subsidy** props (Refs #4761).
typedef ProvinceOverlayGrantSubsidyProps = ({
  bool showGrantAid,
  bool grantAidEnabled,
  bool grantAidPending,
  String? grantAidRejectionReason,
  VoidCallback? onGrantAidTap,
  bool showSetSubsidy,
  bool setSubsidyEnabled,
  bool setSubsidyPending,
  String? setSubsidyRejectionReason,
  VoidCallback? onSetSubsidyTap,
});

const ProvinceOverlayGrantSubsidyProps kProvinceOverlayGrantSubsidyHidden = (
  showGrantAid: false,
  grantAidEnabled: false,
  grantAidPending: false,
  grantAidRejectionReason: null,
  onGrantAidTap: null,
  showSetSubsidy: false,
  setSubsidyEnabled: false,
  setSubsidyPending: false,
  setSubsidyRejectionReason: null,
  onSetSubsidyTap: null,
);
