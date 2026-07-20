import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskRepository 保存→読込', () {
    test('保存したタスク一覧をそのまま読み込める（追加順を維持）', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = TaskRepository();
      final tasks = [
        const Task(id: 1, title: '牛乳を買う'),
        Task(
          id: 2,
          title: 'レビュー依頼',
          isCompleted: true,
          dueDate: DateTime(2026, 7, 20),
        ),
      ];

      await repository.save(tasks);
      final loaded = await repository.load();

      expect(loaded.length, 2);
      expect(loaded[0].id, 1);
      expect(loaded[0].title, '牛乳を買う');
      expect(loaded[1].id, 2);
      expect(loaded[1].isCompleted, true);
      expect(loaded[1].dueDate, DateTime(2026, 7, 20));
    });

    test('保存形式は契約通り（キーtodo_app.tasks、version 1のJSON）', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = TaskRepository();

      await repository.save([const Task(id: 1, title: 'a')]);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('todo_app.tasks');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['version'], 1);
      expect(decoded['tasks'], isA<List<dynamic>>());
    });
  });

  group('TaskRepository 読込の回復規則（契約: 読込規則1〜4 / FR-011）', () {
    test('キーが存在しない（初回起動）→ 空一覧', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await TaskRepository().load(), isEmpty);
    });

    test('JSONとしてパース不能 → 空一覧でクラッシュしない', () async {
      SharedPreferences.setMockInitialValues(
          {'todo_app.tasks': '{broken json'});

      expect(await TaskRepository().load(), isEmpty);
    });

    test('versionが1以外 → 空一覧', () async {
      SharedPreferences.setMockInitialValues({
        'todo_app.tasks': jsonEncode({'version': 2, 'tasks': []}),
      });

      expect(await TaskRepository().load(), isEmpty);
    });

    test('構造不正（tasksが配列でない・トップレベルがオブジェクトでない）→ 空一覧', () async {
      SharedPreferences.setMockInitialValues({
        'todo_app.tasks': jsonEncode({'version': 1, 'tasks': 'oops'}),
      });
      expect(await TaskRepository().load(), isEmpty);

      SharedPreferences.setMockInitialValues({
        'todo_app.tasks': jsonEncode([1, 2, 3]),
      });
      expect(await TaskRepository().load(), isEmpty);
    });

    test('不正な要素のみ読み飛ばし、正常な要素は読み込む', () async {
      SharedPreferences.setMockInitialValues({
        'todo_app.tasks': jsonEncode({
          'version': 1,
          'tasks': [
            {'id': 1, 'title': '正常', 'isCompleted': false, 'dueDate': null},
            {'id': 'bad', 'title': '型不正', 'isCompleted': false},
            'not a map',
            {'id': 3, 'title': 'これも正常', 'isCompleted': true, 'dueDate': null},
          ],
        }),
      });

      final loaded = await TaskRepository().load();

      expect(loaded.length, 2);
      expect(loaded[0].title, '正常');
      expect(loaded[1].title, 'これも正常');
    });
  });
}
