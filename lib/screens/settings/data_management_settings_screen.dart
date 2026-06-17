import 'package:flutter/material.dart';
import '../../models/settings_option.dart';
import '../../services/json_migrator.dart';

class DataManagementSettingsOption extends SettingsOption {
  const DataManagementSettingsOption()
      : super(
          title: 'Data Management',
          subtitle: 'Backup, restore, and migrate data',
          icon: Icons.storage_outlined,
        );

  @override
  Widget buildScreen(BuildContext context) {
    return const DataManagementSettingsScreen();
  }
}

class DataManagementSettingsScreen extends StatefulWidget {
  const DataManagementSettingsScreen({super.key});

  @override
  State<DataManagementSettingsScreen> createState() => _DataManagementSettingsScreenState();
}

class _DataManagementSettingsScreenState extends State<DataManagementSettingsScreen> {
  bool _isChecking = true;
  bool _hasJsonFiles = false;

  @override
  void initState() {
    super.initState();
    _checkForJsonFiles();
  }

  Future<void> _checkForJsonFiles() async {
    final hasFiles = await JsonMigratorService.hasJsonFilesToMigrate();
    if (mounted) {
      setState(() {
        _hasJsonFiles = hasFiles;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Management'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Migration',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasJsonFiles)
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Migrate JSON Data'),
              subtitle: const Text('Import books and history from backup files'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _runMigration(context),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No JSON backup files found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Backup',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Create Backup'),
            subtitle: const Text('Export your library to a JSON file'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from Backup'),
            subtitle: const Text('Import data from a JSON backup file'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restore feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _runMigration(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final preview = await JsonMigratorService.previewJsonData();

    if (!mounted) return;

    if (preview.hasErrors) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error reading JSON files:\n${preview.errors.join('\n')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!preview.hasMigratableData) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No new data to migrate')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate JSON Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The following data will be imported:'),
            const SizedBox(height: 16),
            if (preview.totalBooksInJson > 0) ...[
              Text(
                'Books: ${preview.newBooks} new',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (preview.totalBooksInJson != preview.newBooks)
                Text(
                  '  (${preview.totalBooksInJson} total in file, ${preview.totalBooksInJson - preview.newBooks} already exist)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
            if (preview.totalHistoryInJson > 0) ...[
              const SizedBox(height: 8),
              Text(
                'History: ${preview.newHistoryEntries} new entries',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (preview.totalHistoryInJson != preview.newHistoryEntries)
                Text(
                  '  (${preview.totalHistoryInJson} total in file, ${preview.totalHistoryInJson - preview.newHistoryEntries} already exist)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await JsonMigratorService.migrateJsonToSqlite();

    if (!mounted) return;

    if (result.hasErrors) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Migration completed with errors:\n${result.errors.join('\n')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else if (result.hasMigratedAnything) {
      final parts = <String>[];
      if (result.booksMigrated > 0) parts.add('${result.booksMigrated} books');
      if (result.historyEntriesMigrated > 0) parts.add('${result.historyEntriesMigrated} history entries');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Migrated ${parts.join(' and ')} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
