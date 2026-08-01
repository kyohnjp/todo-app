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

  /// [dueDate] は「渡さない=維持」と「nullを渡す=解除」を区別するため、
  /// 値ではなく値を返す関数で受け取る（nullable×copyWithの定番パターン）。
  /// 例: 設定 `copyWith(dueDate: () => date)` ／ 解除 `copyWith(dueDate: () => null)`
  Task copyWith({
    String? title,
    bool? isCompleted,
    DateTime? Function()? dueDate,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        dueDate: dueDate == null ? this.dueDate : dueDate(),
      );

  /// 期限切れか（FR-009）。期限が[today]より前の日付、かつ未完了のときのみtrue。
  /// 日単位で比較し、期限当日は期限切れ扱いしない（data-model.md）。
  bool isOverdue(DateTime today) {
    final due = dueDate;
    if (due == null || isCompleted) return false;
    final dueDay = DateTime(due.year, due.month, due.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return dueDay.isBefore(todayDay);
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
