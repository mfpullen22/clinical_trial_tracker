import 'package:clinical_trial_tracker/home_screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Application());
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    /// Try changing this and hot reloading the application.
    ///
    /// To create a custom theme:
    /// ```shell
    /// dart forui theme create [theme template].
    /// ```
    final theme = blueDark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // TODO: replace with your application's supported locales.
      supportedLocales: FLocalizations.supportedLocales,
      // TODO: add your application's localizations delegates.
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      // MaterialApp's theme is also animated by default with the same duration and curve.
      // See https://api.flutter.dev/flutter/material/MaterialApp/themeAnimationStyle.html for how to configure this.
      //
      // There is a known issue with implicitly animated widgets where their transition occurs AFTER the theme's.
      // See https://github.com/forus-labs/forui/issues/670.
      theme: theme.toApproximateMaterialTheme(),
      builder: (_, child) => FAnimatedTheme(data: theme, child: child!),
      // You can also replace FScaffold with Material Scaffold.
      home: const FScaffold(
        header: FHeader.nested(
          title: Text('Clinical Trial Tracker'),
          titleAlignment: Alignment.center,
        ),
        child: HomeScreen(),
      ),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Text('Count: $_count'),
        FButton(
          onPress: () => setState(() => _count++),
          suffix: const Icon(FIcons.chevronsUp),
          child: const Text('Increase'),
        ),
      ],
    ),
  );
}
