import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_item.dart';
import '../providers/app_providers.dart';

class TaskBoardScreen extends ConsumerWidget {
  const TaskBoardScreen({super.key});

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What needs doing?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                final name = ref.read(displayNameProvider) ?? 'Anonymous';
                ref.read(supabaseServiceProvider).addTask(title, name);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final columns = {
            TaskStatus.todo: tasks.where((t) => t.status == TaskStatus.todo).toList(),
            TaskStatus.inProgress: tasks.where((t) => t.status == TaskStatus.inProgress).toList(),
            TaskStatus.done: tasks.where((t) => t.status == TaskStatus.done).toList(),
          };

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: TaskStatus.values.map((status) {
                return _TaskColumn(status: status, tasks: columns[status]!);
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading tasks: $e')),
      ),
    );
  }
}

class _TaskColumn extends ConsumerWidget {
  final TaskStatus status;
  final List<TaskItem> tasks;

  const _TaskColumn({required this.status, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Text(
                  status.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${tasks.length}',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          ...tasks.map((task) => _TaskCard(task: task)),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('No tasks', style: TextStyle(color: Colors.grey.shade500)),
            ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskItem task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(task.title),
        subtitle: Text('by ${task.createdBy}', style: const TextStyle(fontSize: 11)),
        trailing: task.status != TaskStatus.done
            ? IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                tooltip: 'Move to ${task.status.next.label}',
                onPressed: () =>
                    ref.read(supabaseServiceProvider).advanceTask(task),
              )
            : const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ),
    );
  }
}
