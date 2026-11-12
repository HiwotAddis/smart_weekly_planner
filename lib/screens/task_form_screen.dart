import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    this.existingTask,
    this.taskService,
  });

  final Task? existingTask;
  final TaskService? taskService;

  bool get isEditing => existingTask != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _remainingHoursController;
  late final TextEditingController _remainingMinutesController;

  late final TaskService _taskService;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TaskPriority selectedPriority = TaskPriority.medium;

  bool _loading = false;
  String? _error;
  bool _hasExplicitTime = false;

  @override
  void initState() {
    super.initState();
    _taskService = widget.taskService ?? TaskService();

    final existing = widget.existingTask;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');

    final estimated = existing?.estimatedMinutes ?? 0;
    _hoursController = TextEditingController(
      text: existing == null ? '' : '${estimated ~/ 60}',
    );
    _minutesController = TextEditingController(
      text: existing == null ? '' : '${estimated % 60}',
    );

    final remaining = existing?.remainingMinutes ?? estimated;
    _remainingHoursController = TextEditingController(
      text: existing == null ? '' : '${remaining ~/ 60}',
    );
    _remainingMinutesController = TextEditingController(
      text: existing == null ? '' : '${remaining % 60}',
    );

    if (existing != null) {
      selectedDate = DateTime(
        existing.deadline.year,
        existing.deadline.month,
        existing.deadline.day,
      );
      selectedTime = TimeOfDay.fromDateTime(existing.deadline);
      _hasExplicitTime = !(existing.deadline.hour == 23 &&
          existing.deadline.minute == 59);
      if (!_hasExplicitTime) {
        selectedTime = null;
      }
      selectedPriority = existing.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _remainingHoursController.dispose();
    _remainingMinutesController.dispose();
    super.dispose();
  }

  Future<void> pickDeadlineDate() async {
    final now = DateTime.now();
    final existingDate = selectedDate;
    final firstDate = widget.isEditing &&
            existingDate != null &&
            existingDate.isBefore(DateTime(now.year, now.month, now.day))
        ? existingDate
        : DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickDeadlineTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
        _hasExplicitTime = true;
      });
    }
  }

  void _clearDeadlineTime() {
    setState(() {
      selectedTime = null;
      _hasExplicitTime = false;
    });
  }

  int _parseDurationMinutes({
    required TextEditingController hoursController,
    required TextEditingController minutesController,
  }) {
    final hours = int.tryParse(hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(minutesController.text.trim()) ?? 0;
    return (hours * 60) + minutes;
  }

  Future<void> saveTask() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      setState(() => _error = 'Please select a deadline date.');
      return;
    }

    final estimatedMinutes = _parseDurationMinutes(
      hoursController: _hoursController,
      minutesController: _minutesController,
    );

    final estimatedError =
        TaskService.validateEstimatedMinutes(estimatedMinutes);
    if (estimatedError != null) {
      setState(() => _error = estimatedError);
      return;
    }

    final remainingMinutes = widget.isEditing
        ? _parseDurationMinutes(
            hoursController: _remainingHoursController,
            minutesController: _remainingMinutesController,
          )
        : estimatedMinutes;

    final remainingError = TaskService.validateRemainingMinutes(
      remainingMinutes: remainingMinutes,
      estimatedMinutes: estimatedMinutes,
    );
    if (remainingError != null) {
      setState(() => _error = remainingError);
      return;
    }

    final deadline = TaskService.buildDeadline(
      date: selectedDate!,
      time: _hasExplicitTime && selectedTime != null
          ? TimeOfDayLike(
              hour: selectedTime!.hour,
              minute: selectedTime!.minute,
            )
          : null,
    );

    final deadlineError = TaskService.validateDeadline(
      deadline,
      allowPast: widget.isEditing,
    );
    if (deadlineError != null) {
      setState(() => _error = deadlineError);
      return;
    }

    setState(() => _loading = true);

    try {
      final Task saved;
      if (widget.isEditing) {
        saved = await _taskService.updateTask(
          widget.existingTask!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            deadline: deadline,
            estimatedMinutes: estimatedMinutes,
            remainingMinutes: remainingMinutes,
            priority: selectedPriority,
          ),
          allowPastDeadline: true,
        );
      } else {
        saved = await _taskService.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: deadline,
          estimatedMinutes: estimatedMinutes,
          priority: selectedPriority,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, saved);
    } on TaskFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'Create a Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.isEditing
                  ? 'Update your task details'
                  : 'What do you need to accomplish?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEditing
                  ? 'Changes are saved to your account.'
                  : 'Add your task details and let your planner organize your time.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            const Text(
              'Task title',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              enabled: !_loading,
              decoration: const InputDecoration(
                hintText: 'e.g. Study Organic Chemistry',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: TaskService.validateTitle,
            ),
            const SizedBox(height: 20),
            const Text(
              'Description (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              enabled: !_loading,
              decoration: const InputDecoration(
                hintText: 'Add more details about your task...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Deadline date',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading ? null : pickDeadlineDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                selectedDate == null
                    ? 'Choose deadline date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Deadline time (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : pickDeadlineTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      selectedTime == null
                          ? 'Choose deadline time'
                          : selectedTime!.format(context),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                if (selectedTime != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loading ? null : _clearDeadlineTime,
                    tooltip: 'Clear time',
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'If no time is selected, the deadline will be 11:59 PM.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Text(
              'Estimated duration',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _DurationFields(
              hoursController: _hoursController,
              minutesController: _minutesController,
              enabled: !_loading,
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 24),
              const Text(
                'Remaining duration',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _DurationFields(
                hoursController: _remainingHoursController,
                minutesController: _remainingMinutesController,
                enabled: !_loading,
                allowZero: true,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Priority (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              initialValue: selectedPriority,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.name.toUpperCase()),
                );
              }).toList(),
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => selectedPriority = value);
                      }
                    },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loading ? null : saveTask,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(widget.isEditing ? Icons.save_outlined : Icons.add),
              label: Text(widget.isEditing ? 'Save Changes' : 'Create Task'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationFields extends StatelessWidget {
  const _DurationFields({
    required this.hoursController,
    required this.minutesController,
    required this.enabled,
    this.allowZero = false,
  });

  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final bool enabled;
  final bool allowZero;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: hoursController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '0',
              labelText: 'Hours',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return allowZero ? null : 'Enter hours';
              }
              final number = int.tryParse(value);
              if (number == null || number < 0) {
                return 'Enter valid hours';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: minutesController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '0',
              labelText: 'Minutes',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return allowZero ? null : 'Enter minutes';
              }
              final number = int.tryParse(value);
              if (number == null || number < 0 || number > 59) {
                return 'Use 0–59';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
