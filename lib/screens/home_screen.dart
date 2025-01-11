import 'package:fluent_ui/fluent_ui.dart';
import 'package:movie_renamer/widgets/renamer_content.dart';
import 'package:movie_renamer/widgets/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: Text('Movie Renamer'),
      ),
      pane: NavigationPane(
        selected: _selectedTab,
        onChanged: (index) => setState(() => _selectedTab = index),
        toggleable: false,
        displayMode: PaneDisplayMode.minimal,
        size: NavigationPaneSize(openMaxWidth: 208, compactWidth: 48),
        items: [
          PaneItem(
            icon: Icon(FluentIcons.home),
            title: Text('Home'),
            body: RenamerContent(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: Icon(FluentIcons.settings),
            title: Text('Settings'),
            body: SettingsContent(),
          )
        ],
      ),
    );
  }
}
