enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  /// The status a task moves to when the user taps "advance".
  TaskStatus get next {
    switch (this) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.done;
      case TaskStatus.done:
        return TaskStatus.done;
    }
  }

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String createdBy;
  final TaskStatus status;
  final DateTime createdAt;

  TaskItem({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.status,
    required this.createdAt,
  });

  factory TaskItem.fromMap(Map<String, dynamic> data) {
    return TaskItem(
      id: data['id'].toString(),
      title: data['title'] ?? '',
      createdBy: data['created_by'] ?? '',
      status: TaskStatusX.fromString(data['status'] ?? 'todo'),
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'title': title,
      'created_by': createdBy,
      'status': status.name,
    };
  }
}
