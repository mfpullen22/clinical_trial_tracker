import "package:flutter/material.dart";
import "package:forui/forui.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final typography = theme.typography;
    final colors = theme.colors;

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
        FButton(
          onPress: () {},
          style: FButtonStyle.primary(),
          child: const Text("Add New Participant"),
        ),
        const SizedBox(height: 15),
        FButton(
          onPress: () {},
          style: FButtonStyle.primary(),
          child: const Text("Manage Current Participant"),
        ),
      ],
    );
  }
}
