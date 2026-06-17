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
              leading: const Icon(Icons.edit),
              onTap: () async {
                Navigator.of(context).pop();
                await _showRenameDialog(context, book, _updateBook);
              },
              title: const Text('Rename'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              onTap: () async {
                await BookPersistenceService.favoriteABook(book.id);
                final updatedBook = book.copyWith(isFavorite: !book.isFavorite);
                _updateBook(updatedBook);
                Navigator.of(context).pop();
              },
              title: Text(!book.isFavorite ? 'Add to Favorites' : 'Remove from Favorites'),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              onTap: () async {
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

Future<void> _showRenameDialog(
    BuildContext context,
    Book book,
    Function(Book) _updateBook
    ) async {
  final controller = TextEditingController(text: book.title);

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename Book'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Book Title',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) async {
          if (value.trim().isNotEmpty) {
            Navigator.of(context).pop();
            await _renameBook(book, value.trim(), _updateBook);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop();
              await _renameBook(book, controller.text.trim(), _updateBook);
            }
          },
          child: const Text('Rename'),
        ),
      ],
    ),
  );

  controller.dispose();
}

Future<void> _renameBook(
    Book book,
    String newTitle,
    Function(Book) _updateBook
    ) async {
  final updatedBook = book.copyWith(title: newTitle);
  await BookPersistenceService.updateBook(updatedBook);
  _updateBook(updatedBook);
}
