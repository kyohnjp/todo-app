import 'package:flutter/material.dart';

import '../controllers/todo_list_controller.dart';

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
                    return ListTile(
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
