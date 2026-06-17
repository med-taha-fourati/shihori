import 'dart:async';
import 'dart:io';
import 'package:Shihori/services/book_persistence.dart';
import 'package:Shihori/services/bookmark_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/book.dart';
import '../models/bookmark.dart';
import '../providers/reader_settings_provider.dart';
import '../services/page_persistence.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({
    super.key,
    required this.book,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  bool _showAppBar = true;
  bool _showSearchField = false;
  double _progress = 0.0;
  ValueNotifier<int> currentPage = ValueNotifier<int>(1);
  final TextEditingController _searchController = TextEditingController();
  late Book _currentBook;
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  int _currentMatchIndex = 0;
  List<Bookmark> _bookmarks = [];
  Timer? _pageUpdateTimer;
  int? _pendingPageUpdate;
  int? _currentPosition;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _loadBookmarks();
    _loadPdf();
    currentPage = ValueNotifier<int>(_pdfViewerController.pageNumber);
    _pdfViewerController.addListener(() {
      if (_pdfViewerController.pageNumber != currentPage.value) {
        currentPage.value = _pdfViewerController.pageNumber - 1;
      }
    });
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks(widget.book.id);
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
      });
    }
  }

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  void _searchText(String query) {
    if (query.isEmpty) {
      _searchResult.clear();
      setState(() {
        _searchResult = PdfTextSearchResult();
        _currentMatchIndex = 0;
      });
      return;
    }

    final result = _pdfViewerController.searchText(query);
    setState(() {
      _searchResult = result;
      _currentMatchIndex = 0;
    });
    result.addListener(() {
      if (mounted && result.hasResult && _currentMatchIndex == 0) {
        setState(() {
          _searchResult = result;
          _currentMatchIndex = 1;
        });
      }
    });
  }

  void _nextMatch() {
    if (_searchResult.hasResult) {
      _searchResult.nextInstance();
      setState(() {
        _currentMatchIndex = _currentMatchIndex < _searchResult.totalInstanceCount
            ? _currentMatchIndex + 1
            : 1;
      });
    }
  }

  void _previousMatch() {
    if (_searchResult.hasResult) {
      _searchResult.previousInstance();
      setState(() {
        _currentMatchIndex = _currentMatchIndex > 1
            ? _currentMatchIndex - 1
            : _searchResult.totalInstanceCount;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchResult.clear();
    setState(() {
      _showSearchField = false;
      _searchResult = PdfTextSearchResult();
      _currentMatchIndex = 0;
    });
  }

  void _onPageChangedDebounced(int newPageNumber) {
    _pendingPageUpdate = newPageNumber;
    _pageUpdateTimer?.cancel();
    _pageUpdateTimer = Timer(const Duration(milliseconds: 300), () {
      _processPageUpdate(newPageNumber);
    });
  }

  Future<void> _processPageUpdate(int newPageNumber) async {
    if (_pendingPageUpdate != newPageNumber) return;

    if (widget.book.lastReadPage != newPageNumber && widget.book.lastReadPage < newPageNumber) {
      BookPersistenceService.updateLastReadPage(widget.book.id, newPageNumber);
      _currentBook = _currentBook.copyWith(lastReadPage: newPageNumber);
    }

    await PagePersistenceService.updatePagesReadToday(1);
  }

  Future<void> _toggleBookmark() async {
    final pageNumber = currentPage.value + 1;
    final existingBookmark = _bookmarks.where((b) => b.pageNumber == pageNumber).toList();

    if (existingBookmark.isNotEmpty) {
      await BookmarkService.removeBookmark(existingBookmark.first.id!);
      await _loadBookmarks();
    } else {
      final bookmark = Bookmark(
        bookId: widget.book.id,
        pageNumber: pageNumber,
      );
      await BookmarkService.addBookmark(bookmark);
      await _loadBookmarks();
    }
  }

  Future<void> _showBookmarksDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bookmarks'),
        content: SizedBox(
          width: double.maxFinite,
          child: _bookmarks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No bookmarks yet'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = _bookmarks[index];
                    return ListTile(
                      title: Text('Page ${bookmark.pageNumber}'),
                      subtitle: bookmark.label != null && bookmark.label!.isNotEmpty
                          ? Text(bookmark.label!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await BookmarkService.removeBookmark(bookmark.id!);
                          await _loadBookmarks();
                          if (this.context.mounted) {
                            Navigator.of(this.context).pop();
                          }
                        },
                      ),
                      onTap: () {
                        _pdfViewerController.jumpToPage(bookmark.pageNumber);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReaderSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final settings = context.read<ReaderSettingsProvider>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reader Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Grayscale Mode'),
                  subtitle: const Text('OLED friendly dark mode'),
                  value: settings.grayscale,
                  onChanged: (value) {
                    settings.setGrayscale(value);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Invert Colors'),
                  subtitle: const Text('Invert page colors'),
                  value: settings.invertColors,
                  onChanged: (value) {
                    settings.setInvertColors(value);
                    setState(() {});
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Scroll Direction',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<ScrollDirection>(
                  title: const Text('Vertical'),
                  value: ScrollDirection.vertical,
                  groupValue: settings.scrollDirection,
                  onChanged: (value) {
                    settings.setScrollDirection(value!);
                    _clearSearch();
                    setState(() {});
                  },
                ),
                RadioListTile<ScrollDirection>(
                  title: const Text('Horizontal'),
                  value: ScrollDirection.horizontal,
                  groupValue: settings.scrollDirection,
                  onChanged: (value) {
                    settings.setScrollDirection(value!);
                    _clearSearch();
                    setState(() {});
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Scroll Mode',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<ScrollMode>(
                  title: const Text('Continuous'),
                  subtitle: const Text('Smooth scrolling'),
                  value: ScrollMode.continuous,
                  groupValue: settings.scrollMode,
                  onChanged: (value) {
                    settings.setScrollMode(value!);
                    _clearSearch();
                    setState(() {});
                  },
                ),
                RadioListTile<ScrollMode>(
                  title: const Text('Page by Page'),
                  subtitle: const Text('One page at a time'),
                  value: ScrollMode.pageByPage,
                  groupValue: settings.scrollMode,
                  onChanged: (value) {
                    settings.setScrollMode(value!);
                    _clearSearch();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final readerSettings = context.watch<ReaderSettingsProvider>();

    Widget pdfViewer = SfPdfViewer.file(
      File(widget.book.filePath),
      controller: _pdfViewerController,
      scrollDirection: readerSettings.scrollDirection == ScrollDirection.horizontal
          ? PdfScrollDirection.horizontal
          : PdfScrollDirection.vertical,
      pageLayoutMode: readerSettings.scrollMode == ScrollMode.continuous
          ? PdfPageLayoutMode.continuous
          : PdfPageLayoutMode.single,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        if (_hasLoadedOnce && _currentPosition != null && _currentPosition! > 0) {
          _pdfViewerController.jumpToPage(_currentPosition!);
        } else if (widget.book.lastReadPage > 0) {
          _pdfViewerController.jumpToPage(widget.book.lastReadPage);
          _currentPosition = widget.book.lastReadPage;
        }
        _hasLoadedOnce = true;
        setState(() => _isLoading = false);
      },
      onPageChanged: (PdfPageChangedDetails details) {
        _currentPosition = details.newPageNumber;
        _onPageChangedDebounced(details.newPageNumber);
      },
    );

    if (readerSettings.grayscale) {
      pdfViewer = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: pdfViewer,
      );
    }

    if (readerSettings.invertColors) {
      pdfViewer = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: pdfViewer,
      );
    }

    return Scaffold(
      appBar: _showAppBar
          ? AppBar(
              title: _showSearchField
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              hintText: "Search in document...",
                              suffixText: _searchResult.hasResult
                                  ? '$_currentMatchIndex/${_searchResult.totalInstanceCount}'
                                  : _searchController.text.isNotEmpty
                                      ? 'No results'
                                      : null,
                            ),
                            onChanged: _searchText,
                          ),
                        ),
                        if (_searchResult.hasResult) ...[
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: _previousMatch,
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: _nextMatch,
                          ),
                        ],
                      ],
                    )
                  : Text(
                      _currentBook.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              actions: [
                if (!_showSearchField) ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _showSearchField = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: ValueListenableBuilder<int>(
                      valueListenable: currentPage,
                      builder: (context, pageNumber, _) {
                        final isBookmarked = _bookmarks.any((b) => b.pageNumber == pageNumber + 1);
                        return Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border);
                      },
                    ),
                    onPressed: _toggleBookmark,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmarks_outlined),
                    onPressed: _showBookmarksDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _showReaderSettingsDialog,
                  ),
                ],
                if (_showSearchField)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: _clearSearch,
                  ),
              ],
            )
          : null,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleAppBar,
            child: pdfViewer,
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _showAppBar ? 60 : 0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    colorScheme.surface.withAlpha(230),
                    colorScheme.surface.withAlpha(179),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.first_page),
                          onPressed: () {
                            _pdfViewerController.firstPage();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            _pdfViewerController.previousPage();
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: ValueListenableBuilder<int>(
                              valueListenable: currentPage,
                              builder: (context, pageNumber, _) {
                                return Text(
                                  '${pageNumber + 1} / ${_pdfViewerController.pageCount}',
                                  style: theme.textTheme.bodyMedium,
                                );
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            _pdfViewerController.nextPage();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.last_page),
                          onPressed: () {
                            _pdfViewerController.lastPage();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _pageUpdateTimer?.cancel();
    super.dispose();
  }
}
