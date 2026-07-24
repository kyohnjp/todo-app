import 'package:flutter/material.dart';

import 'controllers/todo_list_controller.dart';
import 'pages/home_page.dart';
import 'services/task_repository.dart';

void main() {
  final controller = TodoListController(TaskRepository());
  controller.load();
  runApp(TodoApp(controller: controller));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.controller});

  final TodoListController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: HomePage(controller: controller),
    );
  }
}
