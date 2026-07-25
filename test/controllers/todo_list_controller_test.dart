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

  group('フィルタ（US2 / FR-006）', () {
    Future<TodoListController> controllerWith2Done3Active() async {
      final controller = TodoListController(RecordingTaskRepository());
      await controller.load();
      for (final title in ['a', 'b', 'c', 'd', 'e']) {
        controller.add(title);
      }
      controller.toggleCompleted(controller.tasks[0].id); // a を完了
      controller.toggleCompleted(controller.tasks[1].id); // b を完了
      return controller;
    }

    test('初期値はall、visibleTasksは全件と一致する', () async {
      final controller = await controllerWith2Done3Active();

      expect(controller.filter, TaskFilter.all);
      expect(controller.visibleTasks.length, 5);
    });

    test('activeで未完了のみ、completedで完了のみに絞られる', () async {
      final controller = await controllerWith2Done3Active();

      controller.setFilter(TaskFilter.active);
      expect(controller.visibleTasks.map((t) => t.title), ['c', 'd', 'e']);

      controller.setFilter(TaskFilter.completed);
      expect(controller.visibleTasks.map((t) => t.title), ['a', 'b']);
    });

    test('フィルタは表示の絞り込みのみで、元データを変更しない', () async {
      final controller = await controllerWith2Done3Active();

      controller.setFilter(TaskFilter.completed);
      controller.setFilter(TaskFilter.all);

      expect(controller.tasks.map((t) => t.title), ['a', 'b', 'c', 'd', 'e']);
    });

    test('setFilterでリスナーに通知される', () async {
      final controller = await controllerWith2Done3Active();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setFilter(TaskFilter.active);

      expect(notifications, 1);
    });
  });

  group('rename（US3 / FR-002/007）', () {
    test('タスク名だけが変わり、完了状態は維持される', () async {
      final repository = RecordingTaskRepository();
      final controller = TodoListController(repository);
      await controller.load();
      controller.add('牛乳を買う');
      final id = controller.tasks.single.id;
      controller.toggleCompleted(id);

      final renamed = controller.rename(id, '牛乳と卵を買う');

      expect(renamed, isTrue);
      expect(controller.tasks.single.title, '牛乳と卵を買う');
      expect(controller.tasks.single.isCompleted, true);
      expect(controller.tasks.single.id, id);
    });

    test('前後の空白はtrimされる', () async {
      final controller = TodoListController(RecordingTaskRepository());
      await controller.load();
      controller.add('a');

      controller.rename(controller.tasks.single.id, '  b  ');

      expect(controller.tasks.single.title, 'b');
    });

    test('空・空白のみは拒否し、元の名前を維持して保存もしない', () async {
      final repository = RecordingTaskRepository();
      final controller = TodoListController(repository);
      await controller.load();
      controller.add('元の名前');
      await controller.idle();
      final savesBefore = repository.saveCount;
      final id = controller.tasks.single.id;

      expect(controller.rename(id, ''), isFalse);
      expect(controller.rename(id, '   '), isFalse);
      expect(controller.tasks.single.title, '元の名前');
      await controller.idle();
      expect(repository.saveCount, savesBefore);
    });

    test('変更後の名前が保存される（リロード相当で復元できる）', () async {
      final repository = RecordingTaskRepository();
      final controller = TodoListController(repository);
      await controller.load();
      controller.add('編集前');

      controller.rename(controller.tasks.single.id, '編集後');
      await controller.idle();

      expect(repository.stored.single.title, '編集後');
    });

    test('存在しないidの場合は何も起きない', () async {
      final controller = TodoListController(RecordingTaskRepository());
      await controller.load();
      controller.add('a');

      expect(controller.rename(999, 'b'), isFalse);
      expect(controller.tasks.single.title, 'a');
    });
  });
}
