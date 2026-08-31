import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared table-driven case shape for diplomacy confirm-preview tests.
typedef ConfirmPreviewCase = ({
  String name,
  DiplomaticOrder order,
  String targetDisplayName,
  void Function(List<String> lines, String body) assertLines,
});

const previewHumanId = 'gp1';
const previewTargetGp = 'gp2';
const previewMinorId = 'minor1';
const previewTribeId = 'tribe1';
