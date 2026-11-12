enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime deadline;
  final int estimatedMinutes;
  final TaskPriority priority;
  final int remainingMinutes;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.deadline,
    required this.estimatedMinutes,
    this.priority = TaskPriority.medium,
    int? remainingMinutes,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  }) : remainingMinutes = remainingMinutes ?? estimatedMinutes;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: DateTime.parse(json['deadline'] as String).toLocal(),
      estimatedMinutes: json['estimated_minutes'] as int,
      remainingMinutes: json['remaining_minutes'] as int,
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == (json['priority'] as String? ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'deadline': deadline.toUtc().toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'remaining_minutes': remainingMinutes,
      'priority': priority.name,
      'is_completed': isCompleted,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline.toUtc().toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'remaining_minutes': remainingMinutes,
      'priority': priority.name,
      'is_completed': isCompleted,
    };
  }

  Task copyWith({
    String? title,
    Object? description = _unset,
    DateTime? deadline,
    int? estimatedMinutes,
    TaskPriority? priority,
    int? remainingMinutes,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      deadline: deadline ?? this.deadline,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      priority: priority ?? this.priority,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

const Object _unset = Object();
