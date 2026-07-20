import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/controllers/todo_list_controller.dart';
import 'package:todo_app/pages/home_page.dart';
import 'package:todo_app/services/task_repository.dart';

/// HomePageを実アプリと同じ構成（実リポジトリ＋モックprefs）で起動する。
Future<TodoListController> pumpHomePage(WidgetTester tester) async {
  final controller = TodoListController(TaskRepository());
  await controller.load();
  await tester.pumpWidget(
    MaterialApp(home: HomePage(controller: controller)),
  );
  await tester.pump();
  return controller;
}

Future<void> addTask(WidgetTester tester, String title) async {
  await tester.enterText(find.byType(TextField), title);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('US1-1: タスクの追加', () {
    testWidgets('タスク名を入力して追加すると一覧に未完了として表示される', (tester) async {
      await pumpHomePage(tester);

      await addTask(tester, '牛乳を買う');

      expect(find.text('牛乳を買う'), findsOneWidget);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('追加後は入力欄がクリアされる', (tester) async {
      await pumpHomePage(tester);

      await addTask(tester, '牛乳を買う');

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });
  });

  group('US1-2/3: 完了チェックの切り替え', () {
    testWidgets('チェックを付けると完了の見た目（打ち消し線）になる', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, '牛乳を買う');

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final text = tester.widget<Text>(find.text('牛乳を買う'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('チェックを外すと未完了の見た目に戻る', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, '牛乳を買う');

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final text = tester.widget<Text>(find.text('牛乳を買う'));
      expect(text.style?.decoration, isNot(TextDecoration.lineThrough));
    });
  });

  group('US1-4: タスクの削除', () {
    testWidgets('削除ボタンでそのタスクだけが一覧から消える', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, 'タスクA');
      await addTask(tester, 'タスクB');
      await addTask(tester, 'タスクC');

      // タスクBの行にある削除ボタンを押す
      final rowB = find.widgetWithText(ListTile, 'タスクB');
      await tester.tap(find.descendant(
          of: rowB, matching: find.byIcon(Icons.delete_outline)));
      await tester.pump();

      expect(find.text('タスクA'), findsOneWidget);
      expect(find.text('タスクB'), findsNothing);
      expect(find.text('タスクC'), findsOneWidget);
    });
  });

  group('US1-5: 永続化（リロード相当）', () {
    testWidgets('操作後の状態が保存され、新しいコントローラで復元される', (tester) async {
      final controller = await pumpHomePage(tester);
      await addTask(tester, '残るタスク');
      await addTask(tester, '消すタスク');
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      final rowToDelete = find.widgetWithText(ListTile, '消すタスク');
      await tester.tap(find.descendant(
          of: rowToDelete, matching: find.byIcon(Icons.delete_outline)));
      await tester.pump();
      await controller.idle();

      // リロード相当: 同じストレージから新規に読み込む
      final reloaded = TodoListController(TaskRepository());
      await reloaded.load();

      expect(reloaded.tasks.length, 1);
      expect(reloaded.tasks.single.title, '残るタスク');
      expect(reloaded.tasks.single.isCompleted, true);
    });
  });

  group('US1-6: 空入力の拒否', () {
    testWidgets('空・空白のみで追加しても一覧は変化しない', (tester) async {
      await pumpHomePage(tester);

      await addTask(tester, '');
      await addTask(tester, '   ');

      expect(find.byType(ListTile), findsNothing);
    });
  });

  group('Edge Case: 空状態の表示', () {
    testWidgets('タスク0件のとき空であることが分かる表示が出る', (tester) async {
      await pumpHomePage(tester);

      expect(find.text('タスクはありません'), findsOneWidget);
    });

    testWidgets('タスクを追加すると空状態表示は消える', (tester) async {
      await pumpHomePage(tester);

      await addTask(tester, 'a');

      expect(find.text('タスクはありません'), findsNothing);
    });
  });
}
