import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/task_repository.dart';

/// 一覧の表示フィルタ。画面の状態であり永続化しない（data-model.md）。
enum TaskFilter { all, active, completed }

/// タスク一覧の状態と操作。UIは本クラスのみを参照する。
///
/// 各操作はメモリ上の状態を即時更新して通知し、保存は非同期で直列に行う
/// （research.md R6: 変更のたびに全量保存）。
class TodoListController extends ChangeNotifier {
  /// [now] は期限切れ判定に使う「現在時刻」の供給源。テストで固定時刻を
  /// 注入できるようにするための引数（research.md R3）。省略時は実時刻。
  TodoListController(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final TaskRepository _repository;
  final DateTime Function() _now;
  final List<Task> _tasks = [];
  int _nextId = 1;
  Future<void> _pendingSave = Future.value();

  List<Task> get tasks => List.unmodifiable(_tasks);

  TaskFilter _filter = TaskFilter.all;
  TaskFilter get filter => _filter;

  /// 現在のフィルタで絞り込んだ表示用一覧（FR-006）。元データは変更しない。
  List<Task> get visibleTasks => switch (_filter) {
        TaskFilter.all => tasks,
        TaskFilter.active =>
          List.unmodifiable(_tasks.where((task) => !task.isCompleted)),
        TaskFilter.completed =>
          List.unmodifiable(_tasks.where((task) => task.isCompleted)),
      };

  /// フィルタは画面の状態なので保存はしない。
  void setFilter(TaskFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    notifyListeners();
  }

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

  /// タスク名を変更する（FR-007）。完了状態・期限には影響しない。
  /// trim後に空なら拒否してfalseを返し、元の名前を維持する（FR-002）。
  bool rename(int id, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return false;

    _tasks[index] = _tasks[index].copyWith(title: trimmed);
    _commit();
    return true;
  }

  /// 期限を設定・変更・解除する（FR-008）。nullで解除。名前・完了状態には影響しない。
  void setDueDate(int id, DateTime? dueDate) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;

    _tasks[index] = _tasks[index].copyWith(dueDate: () => dueDate);
    _commit();
  }

  /// 「今日」の基準時刻（DatePickerの初期値などUI向け）。
  DateTime get today => _now();

  /// タスクが期限切れか（FR-009）。判定基準時刻は注入されたnowを使う。
  bool isOverdue(Task task) => task.isOverdue(_now());

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
