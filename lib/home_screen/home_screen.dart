import "package:clinical_trial_tracker/manage_participant_screens/select_participant_screen.dart";
import "package:clinical_trial_tracker/new_participant_screen/new_participant_screen.dart";
import "package:flutter/material.dart";
import "package:forui/forui.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final typography = theme.typography;
    final colors = theme.colors;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Mobile Clinical Trial Participant Management",
          style: typography.sm.copyWith(color: colors.mutedForeground),
        ),
        const FDivider(),
        SizedBox(
          height: screenHeight * 0.20,
        ), // 25% of screen height for spacing above
        SizedBox(
          height: 60,
          child: FButton(
            onPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewParticipantScreen(),
                ),
              );
            },
            style: FButtonStyle.primary(),
            child: const Text("Add New Participant"),
          ),
        ),
        SizedBox(
          height: screenHeight * 0.05,
        ), // 3% of screen height between buttons
        SizedBox(
          height: 60,
          child: FButton(
            onPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelectParticipantScreen(),
                ),
              );
            },
            style: FButtonStyle.primary(),
            child: const Text("Manage Current Participant"),
          ),
        ),
      ],
    );
  }
}
