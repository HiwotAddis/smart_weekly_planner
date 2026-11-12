import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'models/task.dart';
import 'screens/settings_screen.dart';
import 'screens/task_form_screen.dart';
import 'services/task_service.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  SupabaseConfig.assertConfigured();

  // Persist sessions across restarts (default SharedPreferences storage).
  // Only the anon/publishable key is used in the client.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const SmartPlannerApp());
}

class SmartPlannerApp extends StatelessWidget {
  const SmartPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Weekly Planner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6869B7),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(signedInChild: MainScreen()),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  // All tasks created during this app session.
  final List<Task> tasks = [];

  Future<void> addNewTask() async {
    final newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );

    if (!mounted) return;

    if (newTask != null) {
      setState(() {
        tasks.add(newTask);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${newTask.title}" was added successfully!')),
      );
    }
  }

  // Change a task's completion status.
  void toggleTask(String taskId) {
    setState(() {
      final index = tasks.indexWhere((task) => task.id == taskId);

      if (index != -1) {
        tasks[index] = tasks[index].copyWith(
          isCompleted: !tasks[index].isCompleted,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(tasks: tasks),
      const PlaceholderScreen(title: 'Weekly Schedule'),
      TasksScreen(tasks: tasks, onToggleTask: toggleTask),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// HOME SCREEN
class HomeScreen extends StatelessWidget {
  final List<Task> tasks;

  const HomeScreen({super.key, required this.tasks});

  String getTodayDate() {
    final now = DateTime.now();

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = tasks.where((task) => task.isCompleted).length;

    final totalTasks = tasks.length;

    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    final upcomingTasks = tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTodayDate().toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'My Planner',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25263A),
                    ),
                  ),
                  Text(
                    'Make time for what matters.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE8E8F7),
                child: Icon(Icons.person_outline, color: Color(0xFF6869B7)),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Task progress",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF6869B7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: const Color(0xFFE9E9F0),
                ),
                const SizedBox(height: 10),
                Text(
                  '$completedTasks of $totalTasks tasks completed',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Upcoming tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF25263A),
            ),
          ),
          const SizedBox(height: 12),
          if (upcomingTasks.isEmpty)
            const EmptyTasksMessage()
          else
            ...upcomingTasks.take(3).map((task) => TaskCard(task: task)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDF8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF6869B7),
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your planner will help organize tasks around your available time.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF444567)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// TASK MANAGEMENT SCREEN
class TasksScreen extends StatelessWidget {
  final List<Task> tasks;
  final Function(String) onToggleTask;

  const TasksScreen({
    super.key,
    required this.tasks,
    required this.onToggleTask,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();

    final completedTasks = tasks.where((task) => task.isCompleted).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'My Tasks',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your tasks and track your progress.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          Text(
            'Pending (${pendingTasks.length})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (pendingTasks.isEmpty)
            const EmptyTasksMessage()
          else
            ...pendingTasks.map(
              (task) =>
                  TaskCard(task: task, onToggle: () => onToggleTask(task.id)),
            ),
          const SizedBox(height: 28),
          Text(
            'Completed (${completedTasks.length})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (completedTasks.isEmpty)
            Text(
              'Completed tasks will appear here.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...completedTasks.map(
              (task) =>
                  TaskCard(task: task, onToggle: () => onToggleTask(task.id)),
            ),
        ],
      ),
    );
  }
}

// REUSABLE TASK CARD
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onToggle;

  const TaskCard({super.key, required this.task, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(task.deadline);

    final priorityLabel = task.priority.name.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: onToggle == null ? null : (_) => onToggle!(),
            activeColor: const Color(0xFF6869B7),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? Colors.grey
                        : const Color(0xFF25263A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Deadline: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year} · ${time.format(context)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 5),
                Text(
                  '${task.estimatedMinutes ~/ 60}h ${task.estimatedMinutes % 60}m · $priorityLabel priority',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6869B7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// EMPTY TASK MESSAGE
class EmptyTasksMessage extends StatelessWidget {
  const EmptyTasksMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No tasks yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the + button to create your first task.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// TEMPORARY SCREENS
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$title screen will be built next.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
