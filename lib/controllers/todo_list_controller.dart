import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/task_repository.dart';

/// タスク一覧の状態と操作。UIは本クラスのみを参照する。
///
/// 各操作はメモリ上の状態を即時更新して通知し、保存は非同期で直列に行う
/// （research.md R6: 変更のたびに全量保存）。
class TodoListController extends ChangeNotifier {
  TodoListController(this._repository);

  final TaskRepository _repository;
  final List<Task> _tasks = [];
  int _nextId = 1;
  Future<void> _pendingSave = Future.value();

  List<Task> get tasks => List.unmodifiable(_tasks);

  /// 保存済みタスクを読み込む。採番は既存の最大id+1から再開する（research.md R4）。
  Future<void> load() async {
    final loaded = await _repository.load();
    _tasks
      ..clear()
      ..addAll(loaded);
    _nextId = _tasks.isEmpty
        ? 1
        : _tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;
    notifyListeners();
  }

  /// タスクを追加する。trim後に空なら拒否してfalseを返す（FR-001/002）。
  bool add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;

    _tasks.add(Task(id: _nextId++, title: trimmed));
    _commit();
    return true;
  }

  /// 完了/未完了を切り替える（FR-003）。
  void toggleCompleted(int id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;

    _tasks[index] =
        _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
    _commit();
  }

  /// タスクを削除する（FR-004）。
  void remove(int id) {
    final removed = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    if (_tasks.length == removed) return;

    _commit();
  }

  /// 進行中の保存が終わるのを待つ（テスト・終了処理用）。
  Future<void> idle() => _pendingSave;

  void _commit() {
    notifyListeners();
    final snapshot = List.of(_tasks);
    _pendingSave = _pendingSave.then((_) => _repository.save(snapshot));
  }
}
