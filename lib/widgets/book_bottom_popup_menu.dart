import 'package:Shihori/models/book.dart';
import 'package:flutter/material.dart';

Future<void> showBookOptions(
    BuildContext context,
    Function(Book) _removeBook,
    Book book
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
              },
              title: const Text('Favorite'),
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