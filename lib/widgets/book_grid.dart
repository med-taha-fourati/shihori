import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/book.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onBookTap;
  final Function(Book) onHoldBookTap;
  final int crossAxisCount;

  const BookGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    required this.onHoldBookTap,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemAspectRatio = 2 / 3;
    final spacing = 16.0;

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: itemAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _BookGridItem(
          book: book,
          onTap: () => onBookTap(book),
          onHold: () => onHoldBookTap(book)
        );
      },

    );
  }
}

class _BookGridItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onHold;

  const _BookGridItem({
    required this.book,
    required this.onTap,
    required this.onHold
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onHold,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Book Cover
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: book.coverImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: book.coverImagePath!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildDefaultCover(),
                      ),
                    )
                  : _buildDefaultCover(),
            ),
          ),
          const SizedBox(height: 8.0),
          // Book Title
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          // Progress Indicator
          if (book.pageCount > 0) ...[
            const SizedBox(height: 4.0),
            LinearProgressIndicator(
              value: book.progress,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(2.0),
              minHeight: 4.0,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildDefaultCover() {
    return Center(
      child: Icon(
        Icons.menu_book,
        size: 48.0,
        color: Colors.grey[400],
      ),
    );
  }
}
