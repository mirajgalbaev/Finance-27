import 'package:flutter/material.dart';
import 'package:finance_27/models/task_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class TaskTile extends ConsumerWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(name: ref.watch(currencyProvider));

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          leading: IconButton(
            icon: Icon(
              task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: task.isCompleted ? theme.primaryColor : Colors.grey,
            ),
            onPressed: onToggle,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: task.financialOutcome != 0
              ? Text(
                  '${task.financialOutcome > 0 ? "+" : ""}${currencyFormat.format(task.financialOutcome)}',
                  style: TextStyle(
                    color: task.financialOutcome > 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          trailing: task.category != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.category!,
                    style: TextStyle(color: theme.primaryColor, fontSize: 10),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
