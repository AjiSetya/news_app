class Article {
  final String title;
  final String description;
  final String content; // Konten isi berita dari API
  final String author; // Penulis berita dari API
  final String imageUrl;
  final String sourceName;
  final String publishedAt;
  final String url;

  Article({
    required this.title,
    required this.description,
    required this.content,
    required this.author,
    required this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
    required this.url,
  });

  // Membuat konstruktor Article dari JSON yang diterima dari NewsAPI
  factory Article.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>?;

    return Article(
      // mencocokkan data JSON dengan properti Article
      title: json['title'] ?? 'Judul tidak tersedia',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      sourceName: source?['name'] ?? 'Sumber tidak diketahui',
      publishedAt: json['publishedAt'] ?? '',
      url: json['url'] ?? '',
    );
  }

  // Mengubah objek Article menjadi format Map (untuk disimpan ke SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'author': author,
      'urlToImage': imageUrl,
      'source': {'name': sourceName},
      'publishedAt': publishedAt,
      'url': url,
    };
  }
}
