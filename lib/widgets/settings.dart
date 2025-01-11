import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsContent extends StatelessWidget {
  SettingsContent({super.key});

  final _apiKeyController = TextEditingController();
  final Future<SharedPreferencesWithCache> _prefs =
      SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // This cache will only accept the key 'apiKey'.
              allowList: <String>{'apiKey'}));

  void _savePrefs(BuildContext context) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setString('apiKey', _apiKeyController.text);

    if (context.mounted) {
      await displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: const Text('Settings Saved'),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
          severity: InfoBarSeverity.success,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _prefs,
        builder: (BuildContext context,
            AsyncSnapshot<SharedPreferencesWithCache> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: ProgressRing(),
            );
          }
          final SharedPreferencesWithCache prefs = snapshot.data!;
          final apiKey = prefs.getString('apiKey') ?? '';
          _apiKeyController.text = apiKey;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Settings',
                    style: FluentTheme.of(context).typography.title,
                  ),
                  SizedBox(height: 8),
                  InfoLabel(
                    label: 'OMDB API Key',
                    child: TextBox(
                      controller: _apiKeyController,
                      placeholder: 'Enter your API key',
                    ),
                  ),
                  SizedBox(height: 8),
                  FilledButton(
                      onPressed: () {
                        _savePrefs(context);
                      },
                      child: Text('Save'))
                ],
              ),
            ),
          );
        });
  }
}
