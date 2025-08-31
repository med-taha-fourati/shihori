import 'package:Shihori/models/book.dart';
import 'package:flutter/material.dart';

Widget statsWidget(BuildContext context, List<Book> _books) {
  if (_books.isEmpty) {
    return const Center(
      child: Text('No reading statistics available'),
    );
  }

  final totalBooks = _books.length;
  final booksInProgress = _books.where((book) => book.lastReadPage > 0 && book.lastReadPage < book.pageCount).length;
  final completedBooks = _books.where((book) => book.lastReadPage >= book.pageCount && book.pageCount > 0).length;
  final totalPages = _books.fold<int>(0, (sum, book) => sum + book.pageCount);
  final pagesRead = _books.fold<int>(0, (sum, book) => sum + book.lastReadPage);

  _books.forEach((book) => print(book.pageCount));

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Statistics',
          style: Theme.of(context).textTheme.headlineMedium,
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
              _buildStatCard(context, 'Overall Progress', '${((pagesRead / totalPages) * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ],
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
        child:
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
              fontSize: 36,
              color: colorScheme.primary
            ),
          )),
          Text(title),
        ],
      ),
    )
    ),
  );
}