import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings_option.dart';
import '../../providers/reader_settings_provider.dart';

class ReaderSettingsOption extends SettingsOption {
  const ReaderSettingsOption()
      : super(
          title: 'Reader',
          subtitle: 'PDF viewer preferences and display options',
          icon: Icons.menu_book_outlined,
        );

  @override
  Widget buildScreen(BuildContext context) {
    return const ReaderSettingsScreen();
  }
}

class ReaderSettingsScreen extends StatelessWidget {
  const ReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader Settings'),
      ),
      body: Consumer<ReaderSettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Display',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Grayscale Mode'),
                subtitle: const Text('OLED friendly dark mode'),
                value: settings.grayscale,
                onChanged: (value) => settings.setGrayscale(value),
              ),
              SwitchListTile(
                title: const Text('Invert Colors'),
                subtitle: const Text('Invert page colors'),
                value: settings.invertColors,
                onChanged: (value) => settings.setInvertColors(value),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Scroll Direction',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              RadioListTile<ScrollDirection>(
                title: const Text('Vertical'),
                subtitle: const Text('Scroll up and down'),
                value: ScrollDirection.vertical,
                groupValue: settings.scrollDirection,
                onChanged: (value) => settings.setScrollDirection(value!),
              ),
              RadioListTile<ScrollDirection>(
                title: const Text('Horizontal'),
                subtitle: const Text('Scroll left and right'),
                value: ScrollDirection.horizontal,
                groupValue: settings.scrollDirection,
                onChanged: (value) => settings.setScrollDirection(value!),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Scroll Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              RadioListTile<ScrollMode>(
                title: const Text('Continuous'),
                subtitle: const Text('Smooth scrolling between pages'),
                value: ScrollMode.continuous,
                groupValue: settings.scrollMode,
                onChanged: (value) => settings.setScrollMode(value!),
              ),
              RadioListTile<ScrollMode>(
                title: const Text('Page by Page'),
                subtitle: const Text('One page at a time'),
                value: ScrollMode.pageByPage,
                groupValue: settings.scrollMode,
                onChanged: (value) => settings.setScrollMode(value!),
              ),
            ],
          );
        },
      ),
    );
  }
}
