import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  static const String _apiKey = '';

  Future<List<Article>> fetchTopHeadlines() async {
    //.       | base url  |  endpoint      | query parameters
    // https://newsapi.org/v2/top-headlines?country=us&apiKey=API_KEY
    // kita menyusun URI (Uniform Resource Identifier) sesesuai dengan spesifikasi API
    final uri = Uri.https('newsapi.org', '/v2/top-headlines', {
      'country': 'us',
      'pageSize': '20',
    });

    // ambil data dari API dgn memasukkan URI dan API key
    final response = await http.get(uri, headers: {'X-Api-Key': _apiKey});

    // kalau tidak berhasil (bukan 200)
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil berita. HTTP ${response.statusCode}');
    }

    // ubah data dari JSON ke dalam objek Dart (Map<String, dynamic>)
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // cek apakah statusnya ok
    if (data['status'] != 'ok') {
      throw Exception(data['message'] ?? 'Terjadi kesalahan pada API');
    }

    // kita ambil data artikel ke variable baru
    final List<dynamic> articlesJson = data['articles'];

    // memasukkan data ke dalam Class Article
    return articlesJson
        .map((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
