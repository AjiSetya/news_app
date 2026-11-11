import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class BookmarkService {
  static const String _bookmarkKey = 'bookmarked_articles';

  // Mengambil daftar artikel yang tersimpan
  Future<List<Article>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = prefs.getStringList(_bookmarkKey) ?? [];

    return encodedList.map((item) {
      final Map<String, dynamic> json = jsonDecode(item);
      return Article.fromJson(json);
    }).toList();
  }

  // Mengecek apakah suatu artikel sudah dibookmark berdasarkan URL
  Future<bool> isBookmarked(String articleUrl) async {
    if (articleUrl.isEmpty) return false;
    final bookmarks = await getBookmarks();
    return bookmarks.any((article) => article.url == articleUrl);
  }

  // Menambah atau menghapus artikel dari bookmark (toggle)
  Future<bool> toggleBookmark(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    final isExist = bookmarks.any((item) => item.url == article.url);

    if (isExist) {
      // Hapus dari bookmark
      bookmarks.removeWhere((item) => item.url == article.url);
    } else {
      // Tambahkan ke bookmark
      bookmarks.insert(0, article);
    }

    // Simpan kembali daftar yang diperbarui ke SharedPreferences
    final List<String> encodedList =
        bookmarks.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_bookmarkKey, encodedList);

    // Mengembalikan status terbaru (true jika disimpan, false jika dihapus)
    return !isExist;
  }
}

