import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models.dart';

class LocalStore {
  static const _fileName = 'planeats.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<PlanEatsData> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return PlanEatsData.empty();
      final raw = await f.readAsString();
      final jsonMap = jsonDecode(raw);
      if (jsonMap is Map<String, dynamic>) {
        return PlanEatsData.fromJson(jsonMap);
      }
      if (jsonMap is Map) {
        return PlanEatsData.fromJson(jsonMap.cast<String, dynamic>());
      }
      return PlanEatsData.empty();
    } catch (_) {
      return PlanEatsData.empty();
    }
  }

  Future<void> save(PlanEatsData data) async {
    final f = await _file();
    await f.writeAsString(data.toPrettyJson());
  }
}

