import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/models/task.dart';

void main() {
  group('Task.toJson / fromJson', () {
    test('期限なしタスクがJSONを往復しても同じ内容になる', () {
      const task = Task(id: 1, title: '牛乳を買う');

      final restored = Task.fromJson(task.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, 1);
      expect(restored.title, '牛乳を買う');
      expect(restored.isCompleted, false);
      expect(restored.dueDate, isNull);
    });

    test('期限付き・完了済みタスクがJSONを往復しても同じ内容になる', () {
      final task = Task(
        id: 2,
        title: 'レビュー依頼を出す',
        isCompleted: true,
        dueDate: DateTime(2026, 7, 20),
      );

      final restored = Task.fromJson(task.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, 2);
      expect(restored.title, 'レビュー依頼を出す');
      expect(restored.isCompleted, true);
      expect(restored.dueDate, DateTime(2026, 7, 20));
    });

    test('toJsonのdueDateはYYYY-MM-DD形式の文字列になる（契約: storage-schema v1）', () {
      final task = Task(id: 1, title: 'a', dueDate: DateTime(2026, 1, 5));

      expect(task.toJson()['dueDate'], '2026-01-05');
    });

    test('toJsonのdueDateは時刻部を落として日付のみ保存する', () {
      final task =
          Task(id: 1, title: 'a', dueDate: DateTime(2026, 1, 5, 23, 59));

      expect(task.toJson()['dueDate'], '2026-01-05');
    });
  });

  group('Task.fromJson の不正データ検証（契約: 読込規則4）', () {
    Map<String, dynamic> validJson() => {
          'id': 1,
          'title': 'a',
          'isCompleted': false,
          'dueDate': null,
        };

    test('必須フィールド欠落ならnullを返す', () {
      for (final key in ['id', 'title', 'isCompleted']) {
        final json = validJson()..remove(key);
        expect(Task.fromJson(json), isNull, reason: '$key 欠落');
      }
    });

    test('型不一致ならnullを返す', () {
      expect(Task.fromJson(validJson()..['id'] = 'x'), isNull);
      expect(Task.fromJson(validJson()..['title'] = 123), isNull);
      expect(Task.fromJson(validJson()..['isCompleted'] = 'yes'), isNull);
    });

    test('titleがtrim後に空ならnullを返す', () {
      expect(Task.fromJson(validJson()..['title'] = ''), isNull);
      expect(Task.fromJson(validJson()..['title'] = '   '), isNull);
    });

    test('dueDateがYYYY-MM-DD形式でなければnullを返す', () {
      expect(Task.fromJson(validJson()..['dueDate'] = '2026/01/05'), isNull);
      expect(Task.fromJson(validJson()..['dueDate'] = 'あした'), isNull);
      expect(Task.fromJson(validJson()..['dueDate'] = 123), isNull);
    });

    test('Map以外の値ならnullを返す', () {
      expect(Task.fromJson('not a map'), isNull);
      expect(Task.fromJson(null), isNull);
      expect(Task.fromJson([1, 2]), isNull);
    });
  });
}
