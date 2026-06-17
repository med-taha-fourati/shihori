import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings_option.dart';
import '../../providers/theme_provider.dart';

class AppearanceSettingsOption extends SettingsOption {
  const AppearanceSettingsOption()
      : super(
          title: 'Appearance',
          subtitle: 'Theme, colors, and visual preferences',
          icon: Icons.palette_outlined,
        );

  @override
  Widget buildScreen(BuildContext context) {
    return const AppearanceSettingsScreen();
  }
}

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Theme Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow system theme'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Colors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Dynamic Colors'),
                subtitle: const Text('Use system wallpaper colors (Android 12+)'),
                value: themeProvider.useDynamicColor,
                onChanged: themeProvider.isDynamicColorAvailable
                    ? (value) => themeProvider.setUseDynamicColor(value)
                    : null,
              ),
              if (!themeProvider.useDynamicColor) ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Accent Color'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Colors.purple,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.red,
                      Colors.teal,
                      Colors.indigo,
                      Colors.pink,
                    ].map((color) {
                      final isSelected = themeProvider.seedColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () => themeProvider.setSeedColor(color),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
