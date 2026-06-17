import 'package:flutter/material.dart';
import '../models/settings_option.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/reader_settings_screen.dart';
import 'settings/data_management_settings_screen.dart';
import 'settings/about_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<SettingsOption> _settingsOptions = [
    AppearanceSettingsOption(),
    ReaderSettingsOption(),
    DataManagementSettingsOption(),
    AboutSettingsOption(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView.separated(
        itemCount: _settingsOptions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _settingsOptions[index].toListTile(context);
        },
      ),
    );
  }
}
