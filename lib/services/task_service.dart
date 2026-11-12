import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

class TaskFailure implements Exception {
  const TaskFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Supabase-backed task CRUD for the signed-in user.
class TaskService {
  TaskService({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? Supabase.instance.client;

  String get _requireUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const TaskFailure('You must be signed in to manage tasks.');
    }
    return userId;
  }

  static String? validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) {
      return 'Please enter a task title.';
    }
    if (title.length > 200) {
      return 'Title must be 200 characters or fewer.';
    }
    return null;
  }

  static String? validateEstimatedMinutes(int minutes) {
    if (minutes <= 0) {
      return 'Estimated duration must be greater than zero.';
    }
    if (minutes > 24 * 60 * 14) {
      return 'Estimated duration is too large.';
    }
    return null;
  }

  static String? validateRemainingMinutes({
    required int remainingMinutes,
    required int estimatedMinutes,
  }) {
    if (remainingMinutes < 0) {
      return 'Remaining duration cannot be negative.';
    }
    if (remainingMinutes > estimatedMinutes) {
      return 'Remaining duration cannot exceed estimated duration.';
    }
    return null;
  }

  static String? validateDeadline(DateTime deadline, {bool allowPast = false}) {
    if (allowPast) {
      return null;
    }
    if (!deadline.isAfter(DateTime.now())) {
      return 'Deadline must be in the future.';
    }
    return null;
  }

  static DateTime buildDeadline({
    required DateTime date,
    TimeOfDayLike? time,
  }) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 23,
      time?.minute ?? 59,
    );
  }

  Future<List<Task>> fetchTasks() async {
    _requireUserId;
    try {
      final rows = await _client
          .from('tasks')
          .select()
          .order('deadline', ascending: true);

      return (rows as List<dynamic>)
          .map((row) => Task.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (error) {
      throw TaskFailure(_mapError(error.message));
    } catch (_) {
      throw const TaskFailure(
        'Unable to load tasks. Check your connection and try again.',
      );
    }
  }

  Future<Task> createTask({
    required String title,
    String? description,
    required DateTime deadline,
    required int estimatedMinutes,
    TaskPriority priority = TaskPriority.medium,
    int? remainingMinutes,
  }) async {
    final userId = _requireUserId;
    _assertValidInput(
      title: title,
      deadline: deadline,
      estimatedMinutes: estimatedMinutes,
      remainingMinutes: remainingMinutes ?? estimatedMinutes,
      allowPastDeadline: false,
    );

    try {
      final draft = Task(
        id: '',
        userId: userId,
        title: title.trim(),
        description: _normalizeDescription(description),
        deadline: deadline,
        estimatedMinutes: estimatedMinutes,
        remainingMinutes: remainingMinutes ?? estimatedMinutes,
        priority: priority,
      );

      final row = await _client
          .from('tasks')
          .insert(draft.toInsertJson())
          .select()
          .single();

      return Task.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw TaskFailure(_mapError(error.message));
    } on TaskFailure {
      rethrow;
    } catch (_) {
      throw const TaskFailure(
        'Unable to create task. Check your connection and try again.',
      );
    }
  }

  Future<Task> updateTask(Task task, {bool allowPastDeadline = true}) async {
    _requireUserId;
    _assertValidInput(
      title: task.title,
      deadline: task.deadline,
      estimatedMinutes: task.estimatedMinutes,
      remainingMinutes: task.remainingMinutes,
      allowPastDeadline: allowPastDeadline,
    );

    try {
      final row = await _client
          .from('tasks')
          .update(task.toUpdateJson())
          .eq('id', task.id)
          .select()
          .single();

      return Task.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw TaskFailure(_mapError(error.message));
    } on TaskFailure {
      rethrow;
    } catch (_) {
      throw const TaskFailure(
        'Unable to update task. Check your connection and try again.',
      );
    }
  }

  Future<Task> setCompleted({
    required Task task,
    required bool isCompleted,
  }) {
    return updateTask(
      task.copyWith(isCompleted: isCompleted),
      allowPastDeadline: true,
    );
  }

  Future<void> deleteTask(String taskId) async {
    _requireUserId;
    try {
      await _client.from('tasks').delete().eq('id', taskId);
    } on PostgrestException catch (error) {
      throw TaskFailure(_mapError(error.message));
    } catch (_) {
      throw const TaskFailure(
        'Unable to delete task. Check your connection and try again.',
      );
    }
  }

  void _assertValidInput({
    required String title,
    required DateTime deadline,
    required int estimatedMinutes,
    required int remainingMinutes,
    required bool allowPastDeadline,
  }) {
    final titleError = validateTitle(title);
    if (titleError != null) {
      throw TaskFailure(titleError);
    }

    final estimatedError = validateEstimatedMinutes(estimatedMinutes);
    if (estimatedError != null) {
      throw TaskFailure(estimatedError);
    }

    final remainingError = validateRemainingMinutes(
      remainingMinutes: remainingMinutes,
      estimatedMinutes: estimatedMinutes,
    );
    if (remainingError != null) {
      throw TaskFailure(remainingError);
    }

    final deadlineError = validateDeadline(
      deadline,
      allowPast: allowPastDeadline,
    );
    if (deadlineError != null) {
      throw TaskFailure(deadlineError);
    }
  }

  String? _normalizeDescription(String? description) {
    final value = description?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String _mapError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('row-level security') || lower.contains('rls')) {
      return 'You do not have permission to change this task.';
    }
    if (lower.contains('estimated_minutes') ||
        lower.contains('remaining_minutes')) {
      return 'Task duration values are invalid.';
    }
    if (lower.contains('deadline')) {
      return 'Task deadline is invalid.';
    }
    return message.isEmpty ? 'Something went wrong with tasks.' : message;
  }
}

/// Minimal time value so validation helpers stay free of Flutter imports.
class TimeOfDayLike {
  const TimeOfDayLike({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
