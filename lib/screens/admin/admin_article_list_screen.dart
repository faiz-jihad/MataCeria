import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/article_model.dart';
import '../../config/api_config.dart';
import 'admin_article_form_screen.dart';

class AdminArticleListScreen extends StatefulWidget {
  const AdminArticleListScreen({super.key});

  @override
  State<AdminArticleListScreen> createState() => _AdminArticleListScreenState();
}

class _AdminArticleListScreenState extends State<AdminArticleListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Article> _articles = [];

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getArticles();
      setState(() {
        _articles = data.map((json) => Article.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat artikel: $e');
    }
  }

  Future<void> _deleteArticle(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Artikel'),
        content: const Text('Apakah Anda yakin ingin menghapus artikel ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deleteArticle(id);
      if (success) {
        _showSuccessSnackBar('Artikel berhasil dihapus');
        _fetchArticles();
      } else {
        _showErrorSnackBar('Gagal menghapus artikel');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Artikel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminArticleFormScreen()),
          );
          if (result == true) _fetchArticles();
        },
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? const Center(child: Text('Belum ada artikel'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) {
                    final article = _articles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                           child: article.imageUrl != null
                               ? Builder(builder: (context) {
                                   final imageUrl = article.imageUrl!;
                                   final fullUrl = imageUrl.startsWith('http')
                                       ? imageUrl
                                       : '${ApiConfig.baseUrl}$imageUrl';
                                   return ClipRRect(
                                     borderRadius: BorderRadius.circular(10),
                                     child: Image.network(
                                       fullUrl,
                                       fit: BoxFit.cover,
                                       errorBuilder: (_, __, ___) =>
                                           const Icon(Icons.image),
                                     ),
                                   );
                                 })
                               : const Icon(Icons.article),
                        ),
                        title: Text(
                          article.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          article.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminArticleFormScreen(article: article),
                                  ),
                                );
                                if (result == true) _fetchArticles();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteArticle(article.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
