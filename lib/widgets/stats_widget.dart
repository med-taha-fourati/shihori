import 'package:Shihori/models/book.dart';
import 'package:Shihori/widgets/heatmap_widget.dart';
import 'package:flutter/material.dart';
import '../services/page_persistence.dart';

Widget statsWidget(BuildContext context, List<Book> _books) {
  if (_books.isEmpty) {
    return const Center(
      child: Text('No reading statistics available'),
    );
  }

  int calculateTotalDays(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double dayBoxSize = 16.0;
    const double spacing = 4.0;
    final columnWidth = dayBoxSize + spacing;
    final availableWidth = screenWidth - 32;
    final weeksVisible = (availableWidth / columnWidth).floor();
    return weeksVisible * 7; // total days = weeks * 7
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
          // Use FutureBuilder to load stats asynchronously
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
