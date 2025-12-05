import 'package:clinical_trial_tracker/manage_participant_screens/timepoint_detail_screen.dart';
import "package:flutter/material.dart";
import 'package:forui/forui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ParticipantTimepointsScreen extends StatefulWidget {
  final String participantDocId;
  final Map<String, dynamic> participantData;

  const ParticipantTimepointsScreen({
    super.key,
    required this.participantDocId,
    required this.participantData,
  });

  @override
  State<ParticipantTimepointsScreen> createState() =>
      _ParticipantTimepointsScreenState();
}

class _ParticipantTimepointsScreenState
    extends State<ParticipantTimepointsScreen> {
  late Map<String, dynamic> _participantData;

  @override
  void initState() {
    super.initState();
    _participantData = widget.participantData;
  }

  Future<void> _refreshParticipantData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('participants')
          .doc(widget.participantDocId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _participantData = doc.data()!;
        });
      }
    } catch (e) {
      // Handle error silently or show a message
      print('Error refreshing participant data: $e');
    }
  }

  DateTime _calculateDueDate(DateTime screeningDate, int days) {
    return screeningDate.add(Duration(days: days));
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  bool _isTimepointComplete(Map<String, dynamic> timepoint) {
    final tasks = timepoint['tasks'] as Map<String, dynamic>;
    if (tasks.isEmpty) return false;

    for (var task in tasks.values) {
      final taskData = task as Map<String, dynamic>;
      if (taskData['completed'] != true) {
        return false;
      }
    }
    return true;
  }

  List<MapEntry<String, dynamic>> _getSortedTimepoints() {
    final timepoints = _participantData['timepoints'] as Map<String, dynamic>;
    final timepointsList = timepoints.entries.toList();

    // Sort by order field
    timepointsList.sort((a, b) {
      final orderA = (a.value as Map<String, dynamic>)['order'] as int;
      final orderB = (b.value as Map<String, dynamic>)['order'] as int;
      return orderA.compareTo(orderB);
    });

    return timepointsList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final participantId = _participantData['participantId'] as String;
    final screeningDate = (_participantData['screeningDate'] as Timestamp)
        .toDate();
    final trialName = _participantData['trial'] as String;

    final sortedTimepoints = _getSortedTimepoints();

    return FScaffold(
      header: FHeader.nested(
        title: Text('Participant $participantId'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('trials')
            .where('name', isEqualTo: trialName)
            .limit(1)
            .get()
            .then((snapshot) => snapshot.docs.first),
        builder: (context, trialSnapshot) {
          if (trialSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (trialSnapshot.hasError || !trialSnapshot.hasData) {
            return Center(
              child: Text(
                'Error loading trial data',
                style: theme.typography.base.copyWith(color: colors.error),
              ),
            );
          }

          final trialData = trialSnapshot.data!.data() as Map<String, dynamic>;
          final trialTimepoints =
              trialData['timepoints'] as Map<String, dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedTimepoints.length,
            itemBuilder: (context, index) {
              final timepointEntry = sortedTimepoints[index];
              final timepointKey = timepointEntry.key;
              final timepointData =
                  timepointEntry.value as Map<String, dynamic>;

              // Get corresponding trial timepoint data
              final trialTimepointData =
                  trialTimepoints[timepointKey] as Map<String, dynamic>;
              final label = trialTimepointData['label'] as String;
              final days = trialTimepointData['days'];

              // Calculate due date if days is not null
              String dueText;
              if (days != null) {
                final dueDate = _calculateDueDate(screeningDate, days as int);
                dueText = 'Due: ${_formatDate(dueDate)}';
              } else {
                dueText = 'Due: N/A';
              }

              // Determine if timepoint is complete
              final isComplete = _isTimepointComplete(timepointData);

              // Set tile background color based on completion status
              final tileBackgroundColor = isComplete
                  ? const Color(0xFF22C55E).withOpacity(0.2) // Green tint
                  : const Color(0xFFEF4444).withOpacity(0.2); // Red tint

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: tileBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isComplete
                          ? const Color(0xFF22C55E).withOpacity(0.4)
                          : const Color(0xFFEF4444).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: FTile(
                    title: Text(label),
                    subtitle: Text(dueText),
                    suffix: Icon(FIcons.chevronRight, color: colors.primary),
                    onPress: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimepointDetailScreen(
                            participantDocId: widget.participantDocId,
                            participantId: participantId,
                            timepointKey: timepointKey,
                            timepointData: timepointData,
                            trialTimepointData: trialTimepointData,
                          ),
                        ),
                      );
                      // Refresh data after returning from detail screen
                      _refreshParticipantData();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
