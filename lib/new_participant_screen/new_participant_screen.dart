import "package:flutter/material.dart";
import 'package:forui/forui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewParticipantScreen extends StatefulWidget {
  const NewParticipantScreen({super.key});

  @override
  State<NewParticipantScreen> createState() => _NewParticipantScreenState();
}

class _NewParticipantScreenState extends State<NewParticipantScreen> {
  final _participantIdController = TextEditingController();
  String? _selectedTrial;
  DateTime? _screeningDate;
  bool _isLoading = false;
  List<String> _availableTrials = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableTrials();
  }

  @override
  void dispose() {
    _participantIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTrials() async {
    try {
      final trialsSnapshot = await FirebaseFirestore.instance
          .collection('trials')
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        _availableTrials = trialsSnapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error loading trials: $e');
      }
    }
  }

  bool _validateForm() {
    if (_participantIdController.text.trim().isEmpty) {
      _showErrorDialog('Participant ID is required');
      return false;
    }

    if (_selectedTrial == null) {
      _showErrorDialog('Please select a trial');
      return false;
    }

    if (_screeningDate == null) {
      _showErrorDialog('Please select a screening date');
      return false;
    }

    return true;
  }

  Future<void> _submitParticipant() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the trial document to get timepoints
      final trialSnapshot = await FirebaseFirestore.instance
          .collection('trials')
          .where('name', isEqualTo: _selectedTrial)
          .limit(1)
          .get();

      if (trialSnapshot.docs.isEmpty) {
        throw Exception('Trial not found');
      }

      final trialData = trialSnapshot.docs.first.data();
      final timepoints = trialData['timepoints'] as Map<String, dynamic>;

      // Create timepoint maps for the participant
      final Map<String, dynamic> participantTimepoints = {};
      timepoints.forEach((timepointKey, timepointData) {
        final timepointMap = timepointData as Map<String, dynamic>;
        final tasks = timepointMap['tasks'] as List<dynamic>;
        final timepointOrder = timepointMap['order'] as int;

        // Create tasks map for this timepoint
        final Map<String, dynamic> participantTasks = {};
        for (var task in tasks) {
          final taskData = task as Map<String, dynamic>;
          final taskId = taskData['taskId'] as String;
          final taskOrder = taskData['order'] as int;
          participantTasks[taskId] = {
            'taskId': taskId,
            'order': taskOrder,
            'completed': false,
            'completedDate': null,
            'notes': null,
          };
        }

        participantTimepoints[timepointKey] = {
          'timepointName': timepointKey,
          'order': timepointOrder,
          'completed': false,
          'completedDate': null,
          'tasks': participantTasks,
        };
      });

      // Create the participant document
      await FirebaseFirestore.instance.collection('participants').add({
        'participantId': _participantIdController.text.trim(),
        'trial': _selectedTrial,
        'screeningDate': Timestamp.fromDate(_screeningDate!),
        'createdAt': FieldValue.serverTimestamp(),
        'timepoints': participantTimepoints,
      });

      if (mounted) {
        // Show success message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Participant added successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to home screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error creating participant: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Add New Participant'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FCard(
              title: const Text("New Participant Details"),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FTextField(
                    controller: _participantIdController,
                    label: const Text("Participant ID"),
                    hint: "123456",
                    description: const Text(
                      "Enter the unique participant identifier",
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_availableTrials.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    FSelect<String>(
                      label: const Text("Trial"),
                      description: const Text(
                        "Choose the trial for enrollment",
                      ),
                      items: Map.fromEntries(
                        _availableTrials.map((trial) => MapEntry(trial, trial)),
                      ),
                      onChange: (value) {
                        setState(() {
                          _selectedTrial = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Screening Date',
                    style: theme.typography.base.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FCalendar(
                    controller: FCalendarController.date(
                      initialSelection: _screeningDate,
                    ),
                    start: DateTime(2020),
                    end: DateTime.now(),
                    today: DateTime.now(),
                    onPress: (dates) {
                      setState(() {
                        _screeningDate = dates;
                      });
                    },
                  ),
                  if (_screeningDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${_screeningDate!.month}/${_screeningDate!.day}/${_screeningDate!.year}',
                      style: theme.typography.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FButton(
                      onPress: _isLoading ? null : _submitParticipant,
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
                          : const Text("Add Participant"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* import "package:flutter/material.dart";
import 'package:forui/forui.dart';

class NewParticipantScreen extends StatefulWidget {
  const NewParticipantScreen({super.key});

  @override
  State<NewParticipantScreen> createState() => _NewParticipantScreenState();
}

class _NewParticipantScreenState extends State<NewParticipantScreen> {
  @override
  Widget build(BuildContext context) {
    const trials = ["PLATFORM-CM"];

    return FScaffold(
      header: FHeader.nested(
        title: Text('Add New Participant'),
        prefixes: [FHeaderAction.back(onPress: () {})],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FCard(
            title: Text("New Participant Details"),
            child: Column(
              children: [
                FTextField(
                  label: Text("Participant ID"),
                  hint: "123456",
                  description: Text("Enter the unique participant identified"),
                ),
                FSelect<String>.rich(
                  hint: "Select a trial",
                  format: (s) => s,
                  children: [
                    for (final trial in trials)
                      FSelectItem(title: Text(trial), value: trial),
                  ],
                ),
                FDateField.calendar(
                  label: Text('Screening Date'),
                  description: Text('Select the date screening was conducted'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 */
