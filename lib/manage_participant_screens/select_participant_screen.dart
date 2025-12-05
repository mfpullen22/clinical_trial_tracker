import 'package:clinical_trial_tracker/manage_participant_screens/participant_timepoints_screen.dart';
import "package:flutter/material.dart";
import 'package:forui/forui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectParticipantScreen extends StatefulWidget {
  const SelectParticipantScreen({super.key});

  @override
  State<SelectParticipantScreen> createState() =>
      _SelectParticipantScreenState();
}

class _SelectParticipantScreenState extends State<SelectParticipantScreen> {
  final _participantIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _participantIdController.dispose();
    super.dispose();
  }

  Future<void> _lookupParticipant() async {
    final participantId = _participantIdController.text.trim();

    if (participantId.isEmpty) {
      _showErrorDialog('Please enter a participant ID');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final participantSnapshot = await FirebaseFirestore.instance
          .collection('participants')
          .where('participantId', isEqualTo: participantId)
          .limit(1)
          .get();

      if (participantSnapshot.docs.isEmpty) {
        if (mounted) {
          _showErrorDialog('No participant found with ID: $participantId');
        }
      } else {
        // Participant found, navigate to timepoints screen
        final participantDoc = participantSnapshot.docs.first;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParticipantTimepointsScreen(
                participantDocId: participantDoc.id,
                participantData: participantDoc.data(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error looking up participant: $e');
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
    final screenHeight = MediaQuery.of(context).size.height;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Manage Participant'),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: screenHeight * 0.15),
            FCard(
              title: const Text("Participant Lookup"),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FTextField(
                    controller: _participantIdController,
                    label: const Text("Participant ID"),
                    hint: "123456",
                    description: const Text(
                      "Enter the participant ID to manage",
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FButton(
                      onPress: _isLoading ? null : _lookupParticipant,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
