import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// タスク一覧の永続化。
///
/// 保存形式は specs/001-todo-mvp/contracts/storage-schema.md (version 1) が契約。
/// 読込は同契約の回復規則に従い、どんな壊れたデータでも例外を投げず空一覧で返す。
class TaskRepository {
  static const String storageKey = 'todo_app.tasks';
  static const int _schemaVersion = 1;

  Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return [];
      if (decoded['version'] != _schemaVersion) return [];
      final rawTasks = decoded['tasks'];
      if (rawTasks is! List) return [];
      return rawTasks.map(Task.fromJson).whereType<Task>().toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode({
        'version': _schemaVersion,
        'tasks': [for (final task in tasks) task.toJson()],
      }),
    );
  }
}
