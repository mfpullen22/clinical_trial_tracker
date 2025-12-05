import "package:flutter/material.dart";
import 'package:forui/forui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimepointDetailScreen extends StatefulWidget {
  final String participantDocId;
  final String participantId;
  final String timepointKey;
  final Map<String, dynamic> timepointData;
  final Map<String, dynamic> trialTimepointData;

  const TimepointDetailScreen({
    super.key,
    required this.participantDocId,
    required this.participantId,
    required this.timepointKey,
    required this.timepointData,
    required this.trialTimepointData,
  });

  @override
  State<TimepointDetailScreen> createState() => _TimepointDetailScreenState();
}

class _TimepointDetailScreenState extends State<TimepointDetailScreen> {
  late Map<String, bool> _taskCompletionStates;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeTaskStates();
  }

  void _initializeTaskStates() {
    _taskCompletionStates = {};
    final tasks = widget.timepointData['tasks'] as Map<String, dynamic>;

    tasks.forEach((taskId, taskData) {
      final task = taskData as Map<String, dynamic>;
      _taskCompletionStates[taskId] = task['completed'] == true;
    });
  }

  List<Map<String, dynamic>> _getSortedTasks() {
    final trialTasks = widget.trialTimepointData['tasks'] as List<dynamic>;
    final tasks = trialTasks
        .map((task) => task as Map<String, dynamic>)
        .toList();

    // Sort by order field
    tasks.sort((a, b) {
      final orderA = a['order'] as int;
      final orderB = b['order'] as int;
      return orderA.compareTo(orderB);
    });

    return tasks;
  }

  Map<String, List<Map<String, dynamic>>> _groupTasksByCategory() {
    final sortedTasks = _getSortedTasks();
    final Map<String, List<Map<String, dynamic>>> groupedTasks = {};

    for (var task in sortedTasks) {
      final category = task['category'] as String;
      if (!groupedTasks.containsKey(category)) {
        groupedTasks[category] = [];
      }
      groupedTasks[category]!.add(task);
    }

    return groupedTasks;
  }

  Future<void> _submitTaskCompletions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update the participant document
      final updatedTasks = <String, dynamic>{};
      final tasks = widget.timepointData['tasks'] as Map<String, dynamic>;

      tasks.forEach((taskId, taskData) {
        final task = taskData as Map<String, dynamic>;
        updatedTasks[taskId] = {
          ...task,
          'completed': _taskCompletionStates[taskId] ?? false,
          'completedDate': _taskCompletionStates[taskId] == true
              ? FieldValue.serverTimestamp()
              : null,
        };
      });

      // Check if all tasks are completed
      final allTasksComplete = _taskCompletionStates.values.every(
        (completed) => completed,
      );

      await FirebaseFirestore.instance
          .collection('participants')
          .doc(widget.participantDocId)
          .update({
            'timepoints.${widget.timepointKey}.tasks': updatedTasks,
            'timepoints.${widget.timepointKey}.completed': allTasksComplete,
            'timepoints.${widget.timepointKey}.completedDate': allTasksComplete
                ? FieldValue.serverTimestamp()
                : null,
          });

      if (mounted) {
        // Show success message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Task completions updated successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to timepoints screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error updating tasks: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final timepointLabel = widget.trialTimepointData['label'] as String;
    final groupedTasks = _groupTasksByCategory();

    return FScaffold(
      header: FHeader.nested(
        title: Text('PID: ${widget.participantId} - $timepointLabel'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Iterate through categories
                for (var categoryEntry in groupedTasks.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      categoryEntry.key,
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const FDivider(),
                  const SizedBox(height: 8),
                  // Tasks in this category
                  for (var task in categoryEntry.value) ...[
                    _buildTaskCheckbox(task, theme, colors),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
          // Submit button at the bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: FButton(
                onPress: _isLoading ? null : _submitTaskCompletions,
                style: FButtonStyle.primary(),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Submit"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCheckbox(
    Map<String, dynamic> task,
    FThemeData theme,
    FColors colors,
  ) {
    final taskId = task['taskId'] as String;
    final label = task['label'] as String;
    final isRequired = task['required'] == true;
    final notes = task['notes'] as String?;

    return FCheckbox(
      label: Row(
        children: [
          Expanded(child: Text(label, style: theme.typography.base)),
          if (isRequired)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Required',
                style: theme.typography.xs.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      value: _taskCompletionStates[taskId] ?? false,
      onChange: (value) {
        setState(() {
          _taskCompletionStates[taskId] = value;
        });
      },
      description: notes != null
          ? Text(
              notes,
              style: theme.typography.sm.copyWith(
                color: colors.mutedForeground,
              ),
            )
          : null,
    );
  }
}
