import 'package:fluent_ui/fluent_ui.dart';
import 'package:movie_renamer/screens/home_screen.dart';
import 'package:system_theme/system_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      theme: FluentThemeData(
        accentColor: SystemTheme.accentColor.accent.toAccentColor(),
      ),
    );
  }
}
