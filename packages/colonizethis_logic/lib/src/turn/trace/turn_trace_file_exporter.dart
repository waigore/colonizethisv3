import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_logic/src/turn/trace/turn_trace_contracts.dart';

class TurnTraceFileExporter {
  TurnTraceFileExporter({this.rootDirectory = 'tmp', this.maxFilesPerGame = 10})
    : assert(maxFilesPerGame > 0, 'maxFilesPerGame must be positive');

  final String rootDirectory;
  final int maxFilesPerGame;

  Future<File> export(TurnTraceMergedDocument document) async {
    final gameId = document.meta.gameId;
    final turnNumber = document.meta.turnNumber;
    final exportedAt =
        DateTime.tryParse(document.meta.exportedAt)?.toUtc() ??
        DateTime.now().toUtc();
    final directoryPath = '$rootDirectory/turn-traces/$gameId';
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final timestamp = _formatTimestamp(exportedAt);
    final fileName = 'turn-$turnNumber-$timestamp.json';
    final file = File('${directory.path}/$fileName');
    final jsonContent = const JsonEncoder.withIndent(
      '  ',
    ).convert(document.toJson());
    await file.writeAsString('$jsonContent\n');
    await _pruneOlderTraces(directory: directory, keep: maxFilesPerGame);
    return file;
  }

  Future<void> _pruneOlderTraces({
    required Directory directory,
    required int keep,
  }) async {
    final files = <File>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.json')) {
        files.add(entity);
      }
    }
    if (files.length <= keep) {
      return;
    }
    files.sort((File a, File b) {
      final aName = a.uri.pathSegments.isEmpty
          ? a.path
          : a.uri.pathSegments.last;
      final bName = b.uri.pathSegments.isEmpty
          ? b.path
          : b.uri.pathSegments.last;
      final aTimestamp = _extractTimestampToken(aName);
      final bTimestamp = _extractTimestampToken(bName);
      final timestampCompare = aTimestamp.compareTo(bTimestamp);
      if (timestampCompare != 0) {
        return timestampCompare;
      }
      return aName.compareTo(bName);
    });
    final deleteCount = files.length - keep;
    for (var index = 0; index < deleteCount; index++) {
      await files[index].delete();
    }
  }

  String _formatTimestamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    final millisecond = value.millisecond.toString().padLeft(3, '0');
    return '${year}${month}${day}T${hour}${minute}${second}${millisecond}Z';
  }

  String _extractTimestampToken(String fileName) {
    if (!fileName.endsWith('.json')) {
      return '';
    }
    final withoutExt = fileName.substring(0, fileName.length - '.json'.length);
    final lastDash = withoutExt.lastIndexOf('-');
    if (lastDash < 0 || lastDash == withoutExt.length - 1) {
      return '';
    }
    return withoutExt.substring(lastDash + 1);
  }
}
