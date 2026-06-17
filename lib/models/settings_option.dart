import 'package:flutter/material.dart';

abstract class SettingsOption {
  final String title;
  final String subtitle;
  final IconData icon;

  const SettingsOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  Widget buildScreen(BuildContext context);

  ListTile toListTile(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => buildScreen(context),
          ),
        );
      },
    );
  }
}
