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

  group('US2: 完了/未完了フィルタ', () {
    /// 完了2件（タスクA・B）・未完了3件（C・D・E）の状態を作る
    Future<void> setup2Done3Active(WidgetTester tester) async {
      for (final title in ['タスクA', 'タスクB', 'タスクC', 'タスクD', 'タスクE']) {
        await addTask(tester, title);
      }
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pump();
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();
    }

    Future<void> selectFilter(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    testWidgets('US2-4: 初期状態では「すべて」が選択され全タスクが表示される', (tester) async {
      await pumpHomePage(tester);
      await setup2Done3Active(tester);

      expect(find.byType(ListTile), findsNWidgets(5));
      final segmented =
          tester.widget<SegmentedButton<TaskFilter>>(
              find.byType(SegmentedButton<TaskFilter>));
      expect(segmented.selected, {TaskFilter.all});
    });

    testWidgets('US2-1: 「未完了」フィルタで未完了の3件のみ表示される', (tester) async {
      await pumpHomePage(tester);
      await setup2Done3Active(tester);

      await selectFilter(tester, '未完了');

      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('タスクA'), findsNothing);
      expect(find.text('タスクC'), findsOneWidget);
    });

    testWidgets('US2-2: 「完了済み」フィルタで完了の2件のみ表示される', (tester) async {
      await pumpHomePage(tester);
      await setup2Done3Active(tester);

      await selectFilter(tester, '完了済み');

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('タスクA'), findsOneWidget);
      expect(find.text('タスクC'), findsNothing);
    });

    testWidgets('US2-3: 「未完了」表示中に完了チェックを付けるとその場で一覧から消える', (tester) async {
      await pumpHomePage(tester);
      await setup2Done3Active(tester);
      await selectFilter(tester, '未完了');

      // 未完了一覧の先頭（タスクC）にチェックを付ける
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(find.text('タスクC'), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('Edge Case: 絞り込み結果が0件でも空表示が出てフィルタ選択は維持される', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, '未完了だけのタスク');

      await selectFilter(tester, '完了済み');

      expect(find.text('タスクはありません'), findsOneWidget);
      final segmented =
          tester.widget<SegmentedButton<TaskFilter>>(
              find.byType(SegmentedButton<TaskFilter>));
      expect(segmented.selected, {TaskFilter.completed});
    });
  });

  group('US3: タスク名の編集', () {
    Finder dialogTextField() => find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField));

    Future<void> openEditDialog(WidgetTester tester, String title) async {
      await tester.tap(find.widgetWithText(ListTile, title));
      await tester.pumpAndSettle();
    }

    testWidgets('US3-1: タスクをタップすると現在の名前が入った編集ダイアログが開く', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, '牛乳を買う');

      await openEditDialog(tester, '牛乳を買う');

      expect(find.byType(AlertDialog), findsOneWidget);
      final textField = tester.widget<TextField>(dialogTextField());
      expect(textField.controller!.text, '牛乳を買う');
    });

    testWidgets('US3-1: 名前を変えて保存すると一覧の表示が変わり、完了状態は維持される', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, '牛乳を買う');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await openEditDialog(tester, '牛乳を買う');
      await tester.enterText(dialogTextField(), '牛乳と卵を買う');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('牛乳と卵を買う'), findsOneWidget);
      expect(find.text('牛乳を買う'), findsNothing);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('US3-2: 空文字で保存しようとしても元の名前が維持される', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, '元の名前');

      await openEditDialog(tester, '元の名前');
      await tester.enterText(dialogTextField(), '   ');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('元の名前'), findsOneWidget);
    });

    testWidgets('キャンセルすると名前は変わらない', (tester) async {
      await pumpHomePage(tester);
      await addTask(tester, '元の名前');

      await openEditDialog(tester, '元の名前');
      await tester.enterText(dialogTextField(), '変えようとした名前');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('元の名前'), findsOneWidget);
      expect(find.text('変えようとした名前'), findsNothing);
    });

    testWidgets('US3-3: 編集後の名前が保存され、新しいコントローラで復元される', (tester) async {
      final controller = await pumpHomePage(tester);
      await addTask(tester, '編集前');

      await openEditDialog(tester, '編集前');
      await tester.enterText(dialogTextField(), '編集後');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      await controller.idle();

      final reloaded = TodoListController(TaskRepository());
      await reloaded.load();
      expect(reloaded.tasks.single.title, '編集後');
    });
  });
}
