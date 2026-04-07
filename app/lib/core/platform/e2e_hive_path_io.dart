import 'dart:io' show Directory;

String createE2eHivePath() {
  final tmp = Directory.systemTemp.createTempSync('ct_e2e_hive_');
  return tmp.path;
}
