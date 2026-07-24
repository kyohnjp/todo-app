import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/controllers/todo_list_controller.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/services/task_repository.dart';

/// 保存呼び出しを記録するテスト用リポジトリ。
class RecordingTaskRepository implements TaskRepository {
  RecordingTaskRepository({List<Task>? initialTasks})
      : _stored = List.of(initialTasks ?? const []);

  List<Task> _stored;
  int saveCount = 0;

  List<Task> get stored => _stored;

  @override
  Future<List<Task>> load() async => List.of(_stored);

  @override
  Future<void> save(List<Task> tasks) async {
    saveCount++;
    _stored = List.of(tasks);
  }
}

void main() {
  group('load', () {
    test('保存済みタスクを読み込んで公開する', () async {
      final repository = RecordingTaskRepository(initialTasks: [
        const Task(id: 1, title: 'a'),
        const Task(id: 5, title: 'b', isCompleted: true),
      ]);
      final controller = TodoListController(repository);

      await controller.load();

      expect(controller.tasks.length, 2);
      expect(controller.tasks[0].title, 'a');
      expect(controller.tasks[1].isCompleted, true);
    });

    test('読み込み後の採番は既存の最大id+1から始まる', () async {
      final repository = RecordingTaskRepository(
          initialTasks: [const Task(id: 5, title: 'a')]);
      final controller = TodoListController(repository);
      await controller.load();

      controller.add('新タスク');

      expect(controller.tasks.last.id, 6);
    });
  });

  group('add（FR-001/002）', () {
    test('タスクを追加すると一覧の末尾に未完了で入る', () async {
      final controller =
          TodoListController(RecordingTaskRepository());
      await controller.load();

      final added = controller.add('牛乳を買う');

      expect(added, isTrue);
      expect(controller.tasks.length, 1);
      expect(controller.tasks.single.title, '牛乳を買う');
      expect(controller.tasks.single.isCompleted, false);
    });

    test('titleは前後の空白をtrimして保存する', () async {
      final controller =
          TodoListController(RecordingTaskRepository());
      await controller.load();

      controller.add('  牛乳を買う  ');

      expect(controller.tasks.single.title, '牛乳を買う');
    });

    test('空・空白のみのtitleは拒否し、状態を変えず保存もしない', () async {
      final repository = RecordingTaskRepository();
      final controller = TodoListController(repository);
      await controller.load();

      expect(controller.add(''), isFalse);
      expect(controller.add('   '), isFalse);
      expect(controller.tasks, isEmpty);
      expect(repository.saveCount, 0);
    });

    test('idは追加のたびに単調増加し重複しない', () async {
      final controller =
          TodoListController(RecordingTaskRepository());
      await controller.load();

      controller.add('a');
      controller.add('b');
      controller.add('c');

      final ids = controller.tasks.map((t) => t.id).toList();
      expect(ids.toSet().length, 3);
      expect(ids, [ids[0], ids[0] + 1, ids[0] + 2]);
    });
  });

  group('toggleCompleted（FR-003）', () {
    test('未完了→完了→未完了と切り替えられる', () async {
      final controller =
          TodoListController(RecordingTaskRepository());
      await controller.load();
      controller.add('a');
      final id = controller.tasks.single.id;

      controller.toggleCompleted(id);
      expect(controller.tasks.single.isCompleted, true);

      controller.toggleCompleted(id);
      expect(controller.tasks.single.isCompleted, false);
    });
  });

  group('remove（FR-004）', () {
    test('指定したタスクだけが消え、他は順序を保って残る', () async {
      final controller =
          TodoListController(RecordingTaskRepository());
      await controller.load();
      controller.add('a');
      controller.add('b');
      controller.add('c');
      final idOfB = controller.tasks[1].id;

      controller.remove(idOfB);

      expect(controller.tasks.map((t) => t.title), ['a', 'c']);
    });
  });

  group('永続化（FR-005）', () {
    test('add/toggle/removeのたびに保存され、保存内容が最新状態と一致する', () async {
      final repository = RecordingTaskRepository();
      final controller = TodoListController(repository);
      await controller.load();

      controller.add('a');
      await controller.idle();
      expect(repository.saveCount, 1);

      controller.toggleCompleted(controller.tasks.single.id);
      await controller.idle();
      expect(repository.saveCount, 2);
      expect(repository.stored.single.isCompleted, true);

      controller.remove(controller.tasks.single.id);
      await controller.idle();
      expect(repository.saveCount, 3);
      expect(repository.stored, isEmpty);
    });
  });

  group('変更通知', () {
    test('状態が変わる操作でリスナーに通知される', () async {
      final controller =
          TodoListController(RecordingTaskRepository());
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.add('a');
      controller.toggleCompleted(controller.tasks.single.id);
      controller.remove(controller.tasks.single.id);

      expect(notifications, 3);
    });
  });
}
