import 'dart:io';
import 'package:Shihori/widgets/stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;

import '../models/book.dart';
import '../models/profile.dart';
import '../providers/theme_provider.dart';
import '../services/page_persistence.dart';
import '../widgets/book_grid.dart';
import '../services/book_persistence.dart';
import 'reader_screen.dart';
import '../widgets/book_bottom_popup_menu.dart';

import '../providers/helper_methods.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  bool _isSearching = false;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];

  Profile? _profile;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadBooks();
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      setState(() => _isLoading = true);

      final loadedBooks = await BookPersistenceService.loadBooks();

      setState(() {
        _books = loadedBooks;
        _filteredBooks = loadedBooks;
        _isLoading = false;
      });

      debugPrint('Loaded ${_books.length} books from storage');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading books: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isProfileLoading = true);

    final loadedProfile = await PagePersistenceService.loadProfile();

    setState(() {
      _profile = loadedProfile;
      _isProfileLoading = false;
    });

    if (_profile == null) {
      final defaultProfile = Profile(id: DateTime.now().millisecondsSinceEpoch.toString(), pagesReadToday: 0);
      await PagePersistenceService.saveProfile(defaultProfile);

      setState(() => _profile = defaultProfile);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickFile() async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'PDFs',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
          ),
        ],
      );

      if (file != null) {
        final existingBook = _books.any((book) => book.filePath == file.path);
        if (existingBook) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This book is already in your library')),
            );
          }
          return;
        }

        final PdfDocument pd = PdfDocument(inputBytes: await file.readAsBytes());
        final pageCount = pd.pages.count;

        final fileName = path.basename(file.path);
        final newBook = Book(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: cleanFilename(fileName.replaceAll('.pdf', '')),
          filePath: file.path,
          lastOpened: DateTime.now(),
          pageCount: pageCount,
          lastReadPage: 1,
          isFavorite: false
        );

        await BookPersistenceService.addBook(newBook);

        setState(() {
          _books.add(newBook);
          _filterBooks(_searchController.text);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added "${newBook.title}" to library')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding book: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openBook(Book book) async {
    try {
      final updatedBook = book.copyWith(lastOpened: DateTime.now());
      await BookPersistenceService.updateBook(updatedBook);

      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        setState(() {
          _books[index] = updatedBook;
          _filterBooks(_searchController.text);
        });
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderScreen(book: updatedBook),
        ),
      );

      if (result is Book) {
        await _loadBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening book: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBooks = _books;
      } else {
        _filteredBooks = _books
            .where((book) =>
        book.title.toLowerCase().contains(query.toLowerCase()) ||
            book.fileName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchController.clear();
        _filterBooks('');
      }
    });
  }

  Future<void> _removeBook(Book book) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Book'),
          content: Text('Are you sure you want to remove "${book.title}" from your library?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (book.lastReadPage > 0) {
          await PagePersistenceService.updatePagesReadToday(-book.lastReadPage);
        }
        await BookPersistenceService.removeBook(book.id);
        setState(() {
          _books.removeWhere((b) => b.id == book.id);

          _refreshLibrary();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${book.title}" from library')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing book: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshLibrary() async {
    await _loadBooks();
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Library refreshed')),
    //   );
    // }
  }



  Future<void> _openBookDialog(Book book) async {
    showBookOptions(context, _removeBook, book, (updatedBook) {
        final index = _books.indexWhere((b) => b.id == book.id);
        if (index != -1) {
          setState(() {
            _books[index] = updatedBook;
            _filterBooks(_searchController.text);
          });
        }
    });
  }

  Widget _buildLibraryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No books added yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLibrary,
      child: BookGrid(
        books: _filteredBooks,
        onBookTap: _openBook,
        onHoldBookTap: _openBookDialog,
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favoriteBooks = _filteredBooks.where((book) => book.isFavorite == true).toList();

    if (favoriteBooks.isEmpty) {
      return const Center(
        child: Text('Your favorited books will appear here'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLibrary,
      child: BookGrid(
        books: favoriteBooks,
        onBookTap: _openBook,
        onHoldBookTap: _openBookDialog,
      ),
    );
  }

  Widget _buildStatsTab() {
    return statsWidget(context, _books);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search books...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _filterBooks(value);
          },
        )
            : Text(
          'Shihori Reader',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.search_ellipsis,
              progress: _animationController,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Open settings
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildLibraryTab(),
          _buildFavoritesTab(),
          _buildStatsTab(),
        ],
      ),

      floatingActionButton: _selectedIndex == 0 && _filteredBooks.isNotEmpty
          ? FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.add),
      )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.area_chart_outlined),
            selectedIcon: Icon(Icons.area_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}