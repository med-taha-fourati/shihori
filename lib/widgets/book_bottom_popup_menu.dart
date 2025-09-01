import 'package:Shihori/models/book.dart';
import 'package:Shihori/services/book_persistence.dart';
import 'package:flutter/material.dart';

Future<void> showBookOptions(
    BuildContext context,
    Function(Book) _removeBook,
    Book book,
    Function(Book) _updateBook
    ) async {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                book.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              onTap: () async {
                await BookPersistenceService.favoriteABook(book.id);
                final updatedBook = book.copyWith(isFavorite: !book.isFavorite);
                _updateBook(updatedBook);
                Navigator.of(context).pop();
              },
              title: Text(!book.isFavorite ? 'Add to Favorites' : 'Remove from Favorites'),
            ),
            ListTile(
              onTap: () async {
                // Logic to delete the book
                await _removeBook(book);
                Navigator.of(context).pop();
              },
              title: const Text('Delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}