/// やること1件を表すエンティティ。
///
/// 永続化形式は specs/001-todo-mvp/contracts/storage-schema.md (version 1) に従う。
class Task {
  const Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
  });

  final int id;
  final String title;
  final bool isCompleted;

  /// 期限。日付のみ有効（時刻部は保存時に落とす）。nullは期限なし。
  final DateTime? dueDate;

  static final _dueDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'dueDate': dueDate == null ? null : _formatDate(dueDate!),
      };

  /// 契約(読込規則4)に基づき、不正な要素は例外ではなくnullで返す。
  static Task? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final id = json['id'];
    final title = json['title'];
    final isCompleted = json['isCompleted'];
    final rawDueDate = json['dueDate'];

    if (id is! int || title is! String || isCompleted is! bool) return null;
    if (title.trim().isEmpty) return null;

    DateTime? dueDate;
    if (rawDueDate != null) {
      if (rawDueDate is! String || !_dueDatePattern.hasMatch(rawDueDate)) {
        return null;
      }
      dueDate = DateTime.tryParse(rawDueDate);
      if (dueDate == null) return null;
    }

    return Task(
      id: id,
      title: title,
      isCompleted: isCompleted,
      dueDate: dueDate,
    );
  }

  Task copyWith({String? title, bool? isCompleted}) => Task(
        id: id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        dueDate: dueDate,
      );

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
