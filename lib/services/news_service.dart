import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  static const String _apiKey = 'YOUR_API_KEY';

  Future<List<Article>> fetchTopHeadlines({String category = 'general'}) async {
    //.       | base url  |  endpoint      | query parameters
    // https://newsapi.org/v2/top-headlines?country=us&apiKey=API_KEY
    // kita menyusun URI (Uniform Resource Identifier) sesesuai dengan spesifikasi API
    final uri = Uri.https('newsapi.org', '/v2/top-headlines', {
      'country': 'us',
      'category': category,
      'pageSize': '20',
    });
    return _getArticles(uri);
  }

  Future<List<Article>> searchArticles({required String query}) async {
    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'pageSize': '20',
      'sortBy': 'publishedAt',
    });
    return _getArticles(uri);
  }

  Future<List<Article>> _getArticles(Uri uri) async {
    // ambil data dari API dgn memasukkan URI dan API key
    final response = await http.get(uri, headers: {'X-Api-Key': _apiKey});
    // ubah data dari JSON ke dalam objek Dart (Map<String, dynamic>)
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    // kalau tidak berhasil (bukan 200) dan statusnya bukan ok
    if (response.statusCode != 200 || data['status'] != 'ok') {
      throw Exception(data['message'] ?? 'Gagal mengambil berita');
    }
    // kita ambil data artikel ke variable baru
    final articlesJson = data['articles'] as List<dynamic>;

    // memasukkan data ke dalam Class Article dan dimasukkan ke dalam list
    return articlesJson
        .map((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
