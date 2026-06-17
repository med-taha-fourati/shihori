import 'package:Shihori/models/book.dart';
import 'package:Shihori/widgets/heatmap_widget.dart';
import 'package:flutter/material.dart';
import '../services/json_migrator.dart';
import '../services/page_persistence.dart';

Widget statsWidget(BuildContext context, List<Book> _books) {
  int calculateTotalDays(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double dayBoxSize = 16.0;
    const double spacing = 4.0;
    final columnWidth = dayBoxSize + spacing;
    final availableWidth = screenWidth - 32;
    final weeksVisible = (availableWidth / columnWidth).floor();
    return weeksVisible * 7;
  }

  final totalBooks = _books.length;
  final booksInProgress = _books
      .where((book) => book.lastReadPage > 0 && book.lastReadPage < book.pageCount)
      .length;
  final completedBooks = _books
      .where((book) => book.lastReadPage >= book.pageCount && book.pageCount > 0)
      .length;
  final totalPages = _books.fold<int>(0, (sum, book) => sum + book.pageCount);
  final pagesRead = _books.fold<int>(0, (sum, book) => sum + book.lastReadPage);

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Statistics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          FutureBuilder<bool>(
            future: JsonMigratorService.hasJsonFilesToMigrate(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final hasFiles = snapshot.data ?? false;
              if (!hasFiles) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton.icon(
                  onPressed: () => _runMigration(context),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Migrate JSON Data'),
                ),
              );
            },
          ),
          if (_books.isEmpty)
            const Center(
              child: Text('No reading statistics available'),
            )
          else ...[
            FutureBuilder<Map<String, int>>(
              future: PagePersistenceService.loadHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {};
                return ReadingHeatmap(
                  stats: stats,
                  totalDays: calculateTotalDays(context),
                );
              },
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(context, 'Total Books', totalBooks.toString()),
                _buildStatCard(context, 'Books in Progress', booksInProgress.toString()),
                _buildStatCard(context, 'Completed Books', completedBooks.toString()),
                _buildStatCard(context, 'Total Pages', totalPages.toString()),
                _buildStatCard(context, 'Pages Read', pagesRead.toString()),
                if (totalPages > 0)
                  _buildStatCard(
                    context,
                    'Overall Progress',
                    '${((pagesRead / totalPages) * 100).toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildStatCard(BuildContext context, String title, String value) {
  final colorScheme = Theme.of(context).colorScheme;
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  color: colorScheme.primary,
                ),
              ),
            ),
            Text(title),
          ],
        ),
      ),
    ),
  );
}

Future<void> _runMigration(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final preview = await JsonMigratorService.previewJsonData();

  if (!context.mounted) return;

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

  if (!context.mounted) return;

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
