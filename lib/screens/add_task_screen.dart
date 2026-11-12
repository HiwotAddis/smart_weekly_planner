import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  TaskPriority selectedPriority = TaskPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> pickDeadlineDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
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
      });
    }
  }

  void saveTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline date.')),
      );
      return;
    }

    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;

    final totalMinutes = (hours * 60) + minutes;

    if (totalMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimated duration must be greater than zero.'),
        ),
      );
      return;
    }

    final deadline = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime?.hour ?? 23,
      selectedTime?.minute ?? 59,
    );

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      deadline: deadline,
      estimatedMinutes: totalMinutes,
      priority: selectedPriority,
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'What do you need to accomplish?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Add your task details and let your planner organize your time.',
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
              decoration: const InputDecoration(
                hintText: 'e.g. Study Organic Chemistry',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title.';
                }
                return null;
              },
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
              onPressed: pickDeadlineDate,
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

            OutlinedButton.icon(
              onPressed: pickDeadlineTime,
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

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');

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
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');

                      if (number == null || number < 0 || number > 59) {
                        return 'Use 0–59';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Priority',
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
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPriority = value;
                  });
                }
              },
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: saveTask,
              icon: const Icon(Icons.add),
              label: const Text('Create Task'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}
