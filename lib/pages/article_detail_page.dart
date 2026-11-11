import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/news_service.dart';

class ArticleDetailPage extends StatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final BookmarkService _bookmarkService = BookmarkService();
  final NewsService _newsService = NewsService();

  bool _isBookmarked = false;
  late Future<List<Article>> _relatedNewsFuture;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _fetchRelatedArticles();
  }

  // Cek apakah artikel sudah tersimpan sebelumnya
  Future<void> _checkBookmarkStatus() async {
    final status = await _bookmarkService.isBookmarked(widget.article.url);
    if (mounted) {
      setState(() {
        _isBookmarked = status;
      });
    }
  }

  // Mengambil berita terkait berdasarkan kata kunci dari judul
  void _fetchRelatedArticles() {
    final query = _extractKeyword(widget.article.title);
    if (query.isNotEmpty) {
      _relatedNewsFuture = _newsService.searchArticles(query: query);
    } else {
      _relatedNewsFuture = _newsService.fetchTopHeadlines();
    }
  }

  // Ekstrak kata kunci representatif dari judul artikel (menghindari kata hubung)
  String _extractKeyword(String title) {
    const stopWords = {
      'dan', 'di', 'ke', 'dari', 'yang', 'ini', 'itu', 'untuk', 'dengan',
      'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'is', 'are', 'with'
    };

    // Bersihkan karakter selain huruf dan angka
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final words = cleanTitle
        .split(' ')
        .map((w) => w.trim())
        .where((w) => w.length > 3 && !stopWords.contains(w.toLowerCase()))
        .toList();

    if (words.isEmpty) {
      return widget.article.sourceName.split(' ').first;
    }

    // Ambil 1-2 kata pertama sebagai query pencarian berita terkait
    return words.take(2).join(' ');
  }

  // Fungsi toggle bookmark (simpan/hapus)
  Future<void> _toggleBookmark() async {
    final newStatus = await _bookmarkService.toggleBookmark(widget.article);
    if (mounted) {
      setState(() {
        _isBookmarked = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Berita berhasil disimpan' : 'Berita dihapus dari simpanan',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Fungsi membagikan berita
  Future<void> _shareArticle(BuildContext context) async {
    final title = widget.article.title;
    final url = widget.article.url;

    final shareText = url.isNotEmpty
        ? '$title\n\nBaca selengkapnya di: $url'
        : title;

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: title,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membagikan berita')),
        );
      }
    }
  }

  // Fungsi membuka link asli di browser
  Future<void> _openOriginalArticle(BuildContext context) async {
    final uri = Uri.tryParse(widget.article.url);

    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan artikel tidak valid')),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka browser')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat membuka link')),
        );
      }
    }
  }

  String _cleanContent(String rawContent) {
    if (rawContent.isEmpty) return '';
    final regex = RegExp(r'\[\+\d+\s*chars\]');
    return rawContent.replaceAll(regex, '').trim();
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(rawDate).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final cleanedContent = _cleanContent(article.content);
    final formattedDate = _formatDate(article.publishedAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // 1. Header Gambar dengan Tombol Back, Bookmark, dan Share
          SliverAppBar(
            expandedHeight: article.imageUrl.isNotEmpty ? 280 : 0,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              // Tombol Bookmark / Simpan
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    tooltip: _isBookmarked ? 'Hapus Simpanan' : 'Simpan Berita',
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _isBookmarked ? Colors.blueAccent : Colors.black87,
                      size: 20,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                ),
              ),
              // Tombol Share Berita
              Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 8.0, 8.0, 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    tooltip: 'Bagikan Berita',
                    icon: const Icon(Icons.share_rounded, color: Colors.black87, size: 20),
                    onPressed: () => _shareArticle(context),
                  ),
                ),
              ),
            ],
            flexibleSpace: article.imageUrl.isNotEmpty
                ? FlexibleSpaceBar(
                    background: Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : null,
          ),

          // 2. Isi Detail Berita
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Sumber & Tanggal
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(width: 10),
                      if (formattedDate.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Judul Berita
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      height: 1.35,
                    ),
                  ),

                  // Penulis Berita (Author)
                  if (article.author.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Oleh: ${article.author}',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F3F5), thickness: 1.5),
                  const SizedBox(height: 14),

                  // Deskripsi
                  if (article.description.isNotEmpty) ...[
                    Text(
                      article.description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Konten Lengkap
                  if (cleanedContent.isNotEmpty) ...[
                    Text(
                      cleanedContent,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Catatan Edukatif
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 20, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'NewsAPI versi gratis hanya menyediakan cuplikan berita. Untuk membaca artikel selengkapnya, silakan klik tombol di bawah.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tombol Aksi Bawah: Bagikan & Baca Lengkap di Web
                  Row(
                    children: [
                      // Tombol Share Berita berbentuk icon button persegi dengan tooltip
                      Tooltip(
                        message: 'Bagikan berita',
                        child: InkWell(
                          onTap: () => _shareArticle(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Icon(
                              Icons.share_rounded,
                              color: Colors.blue.shade700,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Baca Artikel Asli di Web (Utama & Lebar)
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _openOriginalArticle(context),
                            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                            label: const Text(
                              'Baca Artikel di Web',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Bagian Berita Terkait / Serupa
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Berita Terkait',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildRelatedNewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk merender daftar berita terkait secara horizontal / kartu modern
  Widget _buildRelatedNewsSection() {
    return FutureBuilder<List<Article>>(
      future: _relatedNewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Tidak dapat memuat berita terkait',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          );
        }

        // Filter: Jangan tampilkan artikel yang sedang dibaca sekarang
        final allArticles = snapshot.data ?? [];
        final relatedList = allArticles
            .where((item) => item.url != widget.article.url && item.title != widget.article.title)
            .take(6)
            .toList();

        if (relatedList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Tidak ada berita terkait lainnya saat ini.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          );
        }

        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: relatedList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final relatedArticle = relatedList[index];

              return _buildRelatedCard(context, relatedArticle);
            },
          ),
        );
      },
    );
  }

  // Kartu Berita Terkait Horizontal
  Widget _buildRelatedCard(BuildContext context, Article item) {
    return Container(
      width: 220,
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
            // Membuka halaman detail baru untuk artikel terkait
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailPage(article: item),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        width: double.infinity,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 110,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 110,
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.newspaper_rounded,
                          size: 36,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Sumber
                    Text(
                      item.sourceName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Judul Artikel Terkait
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 3,
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
