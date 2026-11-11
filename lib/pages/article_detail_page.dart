import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  // Fungsi membuka link asli di browser
  Future<void> _openOriginalArticle(BuildContext context) async {
    final uri = Uri.tryParse(article.url);

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

  // Membersihkan tanda batasan karakter NewsAPI (contoh: "... [+1540 chars]")
  String _cleanContent(String rawContent) {
    if (rawContent.isEmpty) return '';
    final regex = RegExp(r'\[\+\d+\s*chars\]');
    return rawContent.replaceAll(regex, '').trim();
  }

  // Format tanggal sederhana agar lebih rapi dibaca siswa
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
    final cleanedContent = _cleanContent(article.content);
    final formattedDate = _formatDate(article.publishedAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // Menggunakan CustomScrollView & SliverAppBar agar selaras dengan halaman utama
      body: CustomScrollView(
        slivers: [
          // 1. Header Gambar dengan Tombol Back Melayang
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

          // 2. Isi Detail Berita dalam Card Putih Bersih
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

                  // Penulis Berita (Author jika ada)
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

                  // Deskripsi / Ringkasan Berita
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

                  // Konten Lengkap Berita (dari API)
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

                  // Info Tambahan Pembatasan API (Edukasi untuk Siswa)
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

                  // Tombol Baca Artikel Asli di Web
                  SizedBox(
                    width: double.infinity,
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
                        'Baca Artikel Lengkap di Web',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
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
}
