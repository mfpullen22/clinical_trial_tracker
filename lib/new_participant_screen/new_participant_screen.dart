import "package:flutter/material.dart";
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
