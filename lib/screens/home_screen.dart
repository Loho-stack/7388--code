import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/ebook.dart';
import '../screens/reader_screen.dart';
import '../screens/settings_screen.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/thumbnail_service.dart';
import '../services/firestore_service.dart';
import '../services/cloud_sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final StorageService _storageService = StorageService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;
  
  late Future<List<Ebook>> _ebooksFuture;
  late Future<List<Ebook>> _cloudBooksFuture;
  String _searchQuery = '';
  String? _selectedGrade;
  String? _selectedCategory;
  bool _showFilters = false;
  Map<String, double> _downloadProgress = {}; // Track download progress per book ID

  // Categories list
  final List<String> _categories = [
    'Textbooks',
    'Revision Books',
    'Readers',
    'Reference Books',
  ];

  @override
  void initState() {
    super.initState();
    _syncAndLoadBooks();
  }

  Future<void> _syncAndLoadBooks() async {
    // Remove bundled books first (offline-safe)
    await _cloudSyncService.removeBundledBooks();
    // Load local books first (always available, offline or online)
    _loadEbooks();
    _loadCloudBooks();
    
    // Try to sync with Firebase if connected (non-blocking)
    try {
      await _cloudSyncService.syncDownloadedBookMetadata();
    } catch (e) {
      print('Cannot sync metadata (offline or error): $e');
      // Continue anyway - user can still read offline books
    }
  }

  void _loadEbooks() {
    setState(() {
      _ebooksFuture = _databaseService.getAllEbooks();
    });
  }

  void _loadCloudBooks() {
    setState(() {
      _cloudBooksFuture = _cloudSyncService.getAvailableCloudBooks();
    });
  }

  String _normalizeGrade(String grade) {
    final trimmed = grade.trim();
    if (trimmed.toUpperCase().startsWith('PP')) {
      return trimmed.toUpperCase();
    }
    if (trimmed.toLowerCase().startsWith('grade ')) {
      return trimmed.substring(6).trim();
    }
    return trimmed;
  }

  Future<void> _downloadBook(Ebook cloudBook) async {
    setState(() {
      _downloadProgress[cloudBook.id] = 0.0;
    });

    try {
      final success = await _cloudSyncService.downloadBook(
        cloudBook,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[cloudBook.id] = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadProgress.remove(cloudBook.id);
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Downloaded: ${cloudBook.title}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Refresh books list after download
          _loadEbooks();
          _loadCloudBooks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Download failed. Please check your internet and try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(cloudBook.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Search Books'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter book title or author...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF36a4da)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe85021), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe85021), width: 2),
            ),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Color(0xFFe85021))),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String? tempGrade = _selectedGrade;
    String? tempCategory = _selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Library Filters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF36a4da),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        size: 28,
                        color: Color(0xFF36a4da),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Grades Section
                const Text(
                  'Select Grade',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    'PP1',
                    'PP2',
                    'Grade 1',
                    'Grade 2',
                    'Grade 3',
                    'Grade 4',
                    'Grade 5',
                    'Grade 6',
                    'Grade 7',
                    'Grade 8',
                    'Grade 9',
                  ].map((grade) {
                    final isSelected = tempGrade == grade;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempGrade = isSelected ? null : grade;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFe85021) : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFe85021),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          grade,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF36a4da),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Categories Section
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: _categories.map((category) {
                    final isSelected = tempCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempCategory = isSelected ? null : category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFe85021),
                            width: 2,
                          ),
                          color: isSelected
                              ? const Color(0xFFe85021).withOpacity(0.1)
                              : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFe85021),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFe85021),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Apply Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedGrade = tempGrade;
                        _selectedCategory = tempCategory;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF35a3d9),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'APPLY FILTERS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reset Filters Button
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setModalState(() {
                        tempGrade = null;
                        tempCategory = null;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF36a4da),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFF36a4da),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF32a5d7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF32a5d7),
        title: const Text(
          'LoHo Kids Library',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Search icon
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.search, size: 26, color: Colors.white),
              onPressed: _showSearchDialog,
            ),
          ),
          // Library filter icon with circular background
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFe84f22),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, size: 24, color: Colors.white),
                onPressed: _showFilterSheet,
              ),
            ),
          ),
          // Settings with circular background
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF36a4da),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, size: 24, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<List<Ebook>>>(
        future: Future.wait([_ebooksFuture, _cloudBooksFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFe85021)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          final allBooks = snapshot.data?[0] ?? [];
          final cloudBooks = snapshot.data?[1] ?? [];
          
          // Filter books based on search, grade, and category
          var filteredBooks = allBooks;
          var filteredCloudBooks = cloudBooks;
          
          if (_searchQuery.isNotEmpty) {
            filteredBooks = filteredBooks
                .where((e) =>
                    e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    e.author.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
            filteredCloudBooks = filteredCloudBooks
                .where((e) =>
                    e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    e.author.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }
          if (_selectedGrade != null) {
            final selected = _normalizeGrade(_selectedGrade!);
            filteredBooks = filteredBooks
                .where((e) => _normalizeGrade(e.grade) == selected)
                .toList();
            filteredCloudBooks = filteredCloudBooks
                .where((e) => _normalizeGrade(e.grade) == selected)
                .toList();
          }
          if (_selectedCategory != null) {
            filteredBooks = filteredBooks.where((e) => e.category == _selectedCategory).toList();
            filteredCloudBooks = filteredCloudBooks.where((e) => e.category == _selectedCategory).toList();
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // When filters are applied, show filtered results
                if (_selectedGrade != null || _selectedCategory != null || _searchQuery.isNotEmpty) ...[
                  _buildSectionHeader(
                    _searchQuery.isNotEmpty 
                      ? 'Search Results' 
                      : 'Filtered Books'
                  ),
                  const SizedBox(height: 16),
                  if (filteredBooks.isNotEmpty) ...[
                    _buildBooksCarousel(filteredBooks, isDownloaded: true),
                    const SizedBox(height: 32),
                  ],
                  
                  // Cloud Books Section
                  if (filteredCloudBooks.isNotEmpty) ...[
                    _buildSectionHeader('Available to Download'),
                    const SizedBox(height: 16),
                    _buildBooksCarousel(filteredCloudBooks, isDownloaded: false),
                    const SizedBox(height: 32),
                  ],
                  if (filteredBooks.isEmpty && filteredCloudBooks.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No books found',
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Show all categories with both downloaded and cloud books
                  ..._categories.map((category) {
                    final downloadedInCategory = allBooks
                        .where((e) => e.category == category)
                        .toList();
                    
                    final cloudInCategory = cloudBooks
                        .where((e) => e.category == category)
                        .toList();
                    
                    final hasBooks = downloadedInCategory.isNotEmpty || cloudInCategory.isNotEmpty;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(category),
                        const SizedBox(height: 16),
                        
                        // Downloaded books in this category
                        if (downloadedInCategory.isNotEmpty) ...[
                          _buildBooksCarousel(downloadedInCategory, isDownloaded: true),
                          const SizedBox(height: 24),
                        ],
                        
                        // Cloud books in this category
                        if (cloudInCategory.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cloud_download,
                                  color: Color(0xFFe85021),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Available to Download',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBooksCarousel(cloudInCategory, isDownloaded: false),
                          const SizedBox(height: 32),
                        ],
                        
                        // Empty state for category
                        if (!hasBooks) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                            child: Center(
                              child: Text(
                                'No books in this category yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ],
                    );
                  }).toList(),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward,
            color: Color(0xFFe85020),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildBooksCarousel(List<Ebook> books, {required bool isDownloaded}) {
    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.library_books,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No books available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: isDownloaded ? 280 : 320, // Extra height for download button
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildBookCard(book, isDownloaded: isDownloaded);
        },
      ),
    );
  }

  Widget _buildBookCard(Ebook book, {required bool isDownloaded}) {
    final isDownloading = _downloadProgress.containsKey(book.id);
    final progress = _downloadProgress[book.id] ?? 0.0;
    
    return GestureDetector(
      onTap: isDownloaded ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReaderScreen(ebook: book),
          ),
        );
      } : null,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover/thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: FutureBuilder<Uint8List?>(
                    future: isDownloaded && book.localPath != null
                        ? _getThumbnail(book.localPath!, coverImagePath: book.coverImagePath)
                        : Future.value(null),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      } else if (!isDownloaded && book.coverImagePath != null) {
                        // Show network image for cloud books
                        return Image.network(
                          book.coverImagePath!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF36a4da).withOpacity(0.3),
                                  const Color(0xFFe85021).withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.menu_book,
                                size: 60,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF36a4da).withOpacity(0.3),
                              const Color(0xFFe85021).withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.menu_book,
                            size: 60,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Book info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  
                  // Download button for cloud books
                  if (!isDownloaded) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: isDownloading
                          ? Column(
                              children: [
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF35a3d9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _downloadBook(book),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF35a3d9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _getThumbnail(String localPath, {String? coverImagePath}) async {
    try {
      final storageDir = await _storageService.getEbooksDirectory();
      final fullPath = '${storageDir.path}/$localPath';
      final thumbnailService = ThumbnailService();
      return await thumbnailService.getThumbnail(fullPath, coverImagePath: coverImagePath);
    } catch (e) {
      return null;
    }
  }
}
