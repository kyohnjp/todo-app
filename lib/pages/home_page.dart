import 'package:flutter/material.dart';

import '../controllers/todo_list_controller.dart';
import '../models/task.dart';

/// タスク一覧のホーム画面（このアプリの唯一の画面）。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final TodoListController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (widget.controller.add(_inputController.text)) {
      _inputController.clear();
    }
  }

  /// タスクの編集ダイアログ（US3: 名前 / US4: 期限）。
  /// 空文字での保存は拒否され元の名前が残る。
  Future<void> _showEditDialog(Task task) {
    return showDialog<void>(
      context: context,
      builder: (_) => _EditTaskDialog(
        currentTitle: task.title,
        currentDueDate: task.dueDate,
        today: widget.controller.today,
        onSave: (title) => widget.controller.rename(task.id, title),
        onDueDateChanged: (dueDate) =>
            widget.controller.setDueDate(task.id, dueDate),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year}/${date.month}/${date.day}';

  /// Flutter webは日本語フォントを遅延ロードするため、初回描画時の文字幅計測が
  /// 不正確でセグメントのラベルが折り返されたまま残ることがある。
  /// フォント計測に依存しない固定幅にして回避する。
  Widget _segmentLabel(String text) => SizedBox(
        width: 64,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'やることを入力',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  tooltip: 'タスクを追加',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => SegmentedButton<TaskFilter>(
                segments: [
                  ButtonSegment(
                      value: TaskFilter.all, label: _segmentLabel('すべて')),
                  ButtonSegment(
                      value: TaskFilter.active, label: _segmentLabel('未完了')),
                  ButtonSegment(
                      value: TaskFilter.completed,
                      label: _segmentLabel('完了済み')),
                ],
                selected: {widget.controller.filter},
                onSelectionChanged: (selection) =>
                    widget.controller.setFilter(selection.first),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final tasks = widget.controller.visibleTasks;
                if (tasks.isEmpty) {
                  return const Center(child: Text('タスクはありません'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final overdue = widget.controller.isOverdue(task);
                    final errorColor = Theme.of(context).colorScheme.error;
                    return ListTile(
                      onTap: () => _showEditDialog(task),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) =>
                            widget.controller.toggleCompleted(task.id),
                      ),
                      title: Text(
                        task.title,
                        style: task.isCompleted
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Theme.of(context).disabledColor,
                              )
                            : null,
                      ),
                      subtitle: task.dueDate == null
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (overdue) ...[
                                  Icon(Icons.warning_amber_rounded,
                                      size: 16, color: errorColor),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  '期限: ${_formatDate(task.dueDate!)}',
                                  style: overdue
                                      ? TextStyle(color: errorColor)
                                      : null,
                                ),
                              ],
                            ),
                      trailing: IconButton(
                        onPressed: () => widget.controller.remove(task.id),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'タスクを削除',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// タスク編集ダイアログ（名前＋期限）。TextEditingControllerの寿命を自身の
/// Stateで管理する（閉じるアニメーション中の破棄済みcontroller参照を防ぐ）。
///
/// 期限の変更は選択した時点で即座に適用される。「保存」「キャンセル」は
/// タスク名の編集だけに作用する。
class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({
    required this.currentTitle,
    required this.currentDueDate,
    required this.today,
    required this.onSave,
    required this.onDueDateChanged,
  });

  final String currentTitle;
  final DateTime? currentDueDate;
  final DateTime today;
  final bool Function(String title) onSave;
  final void Function(DateTime? dueDate) onDueDateChanged;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentTitle);
  late DateTime? _dueDate = widget.currentDueDate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(_controller.text);
    Navigator.of(context).pop();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? widget.today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
    widget.onDueDateChanged(picked);
  }

  void _clearDueDate() {
    setState(() => _dueDate = null);
    widget.onDueDateChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final dueDate = _dueDate;
    return AlertDialog(
      title: const Text('タスクを編集'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(dueDate == null
                    ? '期限なし'
                    : '${dueDate.year}/${dueDate.month}/${dueDate.day}'),
              ),
              TextButton(
                onPressed: _pickDueDate,
                child: Text(dueDate == null ? '期限を設定' : '期限を変更'),
              ),
              if (dueDate != null)
                TextButton(
                  onPressed: _clearDueDate,
                  child: const Text('期限を解除'),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
