import 'package:flutter/material.dart';

import '../models/article.dart';
import '../services/news_service.dart';
import 'article_detail_page.dart';
import 'bookmark_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  // Service untuk mengambil data berita dari API
  final NewsService _newsService = NewsService();

  // ScrollController untuk mengontrol perpindahan scroll dan memantau posisi
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  // Future untuk menampung data asynchronous artikel
  late Future<List<Article>> _newsFuture;

  // Kategori aktif (default: umum / general)
  String _selectedCategory = 'general';

  // Controller input pencarian API dan filter lokal judul
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _localFilterController = TextEditingController();

  // Keyword untuk menyaring judul berita secara lokal
  String _localKeyword = '';

  // Daftar kategori yang didukung
  final List<Map<String, String>> _categories = [
    {'label': 'Umum', 'value': 'general'},
    {'label': 'Bisnis', 'value': 'business'},
    {'label': 'Hiburan', 'value': 'entertainment'},
    {'label': 'Kesehatan', 'value': 'health'},
    {'label': 'Sains', 'value': 'science'},
    {'label': 'Olahraga', 'value': 'sports'},
    {'label': 'Teknologi', 'value': 'technology'},
  ];

  @override
  void initState() {
    super.initState();
    // Memuat berita utama pertama kali
    _fetchNewsByCategory(_selectedCategory);

    // Pantau pergerakan scroll untuk memunculkan tombol 'Kembali ke Atas'
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 250;
      if (shouldShow != _showBackToTop) {
        setState(() {
          _showBackToTop = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _localFilterController.dispose();
    super.dispose();
  }

  // Fungsi melompat kembali ke bagian paling atas
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  // Fungsi memuat berita berdasarkan kategori
  void _fetchNewsByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _newsFuture = _newsService.fetchTopHeadlines(category: category);
    });
  }

  // Fungsi mencari berita via API
  void _searchNews() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _fetchNewsByCategory(_selectedCategory);
      return;
    }
    setState(() {
      _newsFuture = _newsService.searchArticles(query: query);
    });
  }

  // Fungsi menyaring berita di memori HP berdasarkan kata kunci judul
  List<Article> _filterByTitle(List<Article> articles, String keyword) {
    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) {
      return articles;
    }
    return articles.where((article) {
      return article.title.toLowerCase().contains(query);
    }).toList();
  }

  // Fungsi refresh berita
  Future<void> _onRefresh() async {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isNotEmpty) {
        _newsFuture = _newsService.searchArticles(query: query);
      } else {
        _newsFuture = _newsService.fetchTopHeadlines(category: _selectedCategory);
      }
    });
    await _newsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // NestedScrollView memungkinkan bagian atas (Header) menyusut/hilang
      // saat daftar berita di bagian body di-scroll ke bawah.
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            // 1. AppBar utama yang otomatis sembunyi saat scroll
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              title: const Row(
                children: [
                  Icon(Icons.newspaper_rounded, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'News App',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    tooltip: 'Berita Favorit',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F3F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.bookmark_rounded,
                      color: Colors.blueAccent,
                      size: 22,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookmarkPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // 2. Panel Kontrol: Search Bar, Kategori, dan Filter Lokal
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Input Cari Berita (API) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchNews(),
                          decoration: InputDecoration(
                            hintText: 'Cari topik atau kata kunci...',
                            hintStyle: const TextStyle(fontSize: 14, color: Colors.black45),
                            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _fetchNewsByCategory(_selectedCategory);
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent),
                                    onPressed: _searchNews,
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                    // --- Pilihan Kategori (Horizontal Chips) ---
                    SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category['value'];

                          return ChoiceChip(
                            label: Text(category['label']!),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            selected: isSelected,
                            selectedColor: Colors.blueAccent,
                            backgroundColor: const Color(0xFFF1F3F5),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            showCheckmark: false,
                            onSelected: (_) => _fetchNewsByCategory(category['value']!),
                          );
                        },
                      ),
                    ),

                    // --- Filter Cepat Judul Berita (Lokal) ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _localFilterController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Saring judul berita di layar...',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.filter_list_rounded, size: 20, color: Colors.grey),
                            suffixIcon: _localKeyword.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _localFilterController.clear();
                                      setState(() {
                                        _localKeyword = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _localKeyword = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        // Body: Berisi daftar berita yang dapat di-scroll
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: FutureBuilder<List<Article>>(
            future: _newsFuture,
            builder: (context, snapshot) {
              // 1. Kondisi Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Kondisi Terjadi Error
              if (snapshot.hasError) {
                return Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red.shade400),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gagal Mengambil Berita',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 3. Ambil data hasil & terapkan filter lokal judul
              final List<Article> rawArticles = snapshot.data ?? [];
              final List<Article> filteredArticles = _filterByTitle(rawArticles, _localKeyword);

              // 4. Kondisi Berita Kosong
              if (filteredArticles.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.article_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada berita ditemukan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _localKeyword.isNotEmpty
                              ? 'Tidak ada artikel yang cocok dengan filter judul "$_localKeyword"'
                              : 'Silakan pilih kategori lain atau periksa kata kunci pencarian.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 5. Menampilkan List Berita dengan Card Modern & Clean
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: filteredArticles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final article = filteredArticles[index];

                  return _buildNewsCard(context, article, theme);
                },
              );
            },
          ),
        ),
      ),
      // Tombol melompat kembali ke atas (muncul otomatis saat discroll ke bawah)
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        offset: _showBackToTop ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _showBackToTop ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: _showBackToTop ? _scrollToTop : null,
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
            label: const Text(
              'Ke Atas',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  // Widget kartu berita dengan gaya modern dan clean
  Widget _buildNewsCard(BuildContext context, Article article, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailPage(article: article),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar berita dengan border rounded atas
              if (article.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 36, color: Colors.grey.shade400),
                        ),
                      );
                    },
                  ),
                ),

              // Detail konten teks
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Sumber Berita
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.sourceName,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Judul Berita
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Cuplikan Deskripsi
                    if (article.description.isNotEmpty)
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}