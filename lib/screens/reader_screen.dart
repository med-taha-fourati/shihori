import 'dart:io';
import 'package:Shihori/services/book_persistence.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/book.dart';

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

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _loadPdf();
    currentPage = ValueNotifier<int>(_pdfViewerController.pageNumber);
    _pdfViewerController.addListener(() {
      if (_pdfViewerController.pageNumber != currentPage.value) {
        currentPage.value = _pdfViewerController.pageNumber - 1;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool showBookmark = false;
    if (_currentBook.bookmarked != null) {
      showBookmark = _currentBook.bookmarked == currentPage.value;
    }

    return Scaffold(
      appBar: _showAppBar
          ? AppBar(
              title: _showSearchField ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  hintText: "Enter your search entry..."
                ),
                onChanged: (_) {
                  // TODO: Search implementation goes here...
                },
              ) : Text(
                _currentBook.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(!_showSearchField ? Icons.search : Icons.cancel_outlined),
                  onPressed: () {
                    //_pdfViewerController.jumpToPage(5);
                    setState(() {
                      _showSearchField = !_showSearchField;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(showBookmark == false ? Icons.bookmark_border : Icons.bookmark_outlined),
                  onPressed: () {
                    // TODO: Implement bookmark functionality
                    //
                    setState(() {
                      if (_currentBook.bookmarked != null && _currentBook.bookmarked == currentPage.value) {
                        _currentBook.bookmarked = null;
                        showBookmark = false;
                      } else {
                        _currentBook.bookmarked = currentPage.value;
                        showBookmark = true;
                      }
                      debugPrint("${showBookmark} showBookmark");
                      debugPrint("${_currentBook.bookmarked}");
                    });
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'bookmark':
                        setState(() {
                          if (_currentBook.bookmarked == currentPage.value) {
                            _currentBook = _currentBook.copyWith(bookmarked: null);
                          } else {
                            _currentBook = _currentBook.copyWith(bookmarked: currentPage.value);
                          }
                        });
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        enabled: _currentBook.bookmarked != null,
                        value: 'bookmark',
                        child: Text(
                          _currentBook.bookmarked != null
                              ? "Go to last Bookmarked Page"
                              : "No bookmarks yet",
                          style: TextStyle(
                            fontStyle: _currentBook.bookmarked == null ? FontStyle.italic : FontStyle.normal,
                            color: _currentBook.bookmarked != null ? colorScheme.primary : colorScheme.primary.withAlpha(100)
                          )
                        ),
                        onTap: () {
                          setState(() {
                            if (_currentBook.bookmarked != null) {
                              _pdfViewerController.jumpToPage(_currentBook.bookmarked!);
                            } else {
                              return;
                            }
                          });
                        },
                      ),
                    ];
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // PDF Viewer
          GestureDetector(
            onTap: _toggleAppBar,
            child: Stack(
              children: [
                // PDF View
                if (widget.book.filePath.isNotEmpty)
                  SfPdfViewer.file(
                    File(widget.book.filePath),
                    controller: _pdfViewerController,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      // Update book page count
                      final book = widget.book;
                      // if (book.pageCount != details.document.pages.count) {
                      //   // Update the book's page count if needed
                      // }

                      // Jump to last read page
                      if (book.lastReadPage > 0) {
                        _pdfViewerController.jumpToPage(book.lastReadPage);
                      }

                      setState(() => _isLoading = false);
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      // Update last read page
                      if (widget.book.lastReadPage != details.newPageNumber && widget.book.lastReadPage < details.newPageNumber) {
                        BookPersistenceService.updateLastReadPage(widget.book.id, details.newPageNumber);
                        _currentBook = _currentBook.copyWith(lastReadPage: details.newPageNumber);
                      }

                      setState(() {
                        debugPrint("this is being accessed ${currentPage.value}");
                        if (_currentBook.bookmarked == null) {
                          showBookmark = false;
                        } else {
                          showBookmark = _currentBook.bookmarked == currentPage
                              .value;
                        }
                      });
                    },
                  ),
              ],
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Bottom Controls
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
                    colorScheme.surface.withAlpha(230),//.withOpacity(0.9),
                    colorScheme.surface.withAlpha(179),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Bar
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Page Controls
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
    super.dispose();
  }
}
