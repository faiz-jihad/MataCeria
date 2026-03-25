import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/article_model.dart';

class AdminArticleFormScreen extends StatefulWidget {
  final Article? article;
  const AdminArticleFormScreen({super.key, this.article});

  @override
  State<AdminArticleFormScreen> createState() => _AdminArticleFormScreenState();
}

class _AdminArticleFormScreenState extends State<AdminArticleFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late TextEditingController _categoryController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title);
    _contentController = TextEditingController(text: widget.article?.content);
    _imageUrlController = TextEditingController(text: widget.article?.imageUrl);
    _categoryController = TextEditingController(text: widget.article?.category ?? 'Tips');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    
    final data = {
      'title': _titleController.text,
      'content': _contentController.text,
      'imageUrl': _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      'category': _categoryController.text,
    };

    try {
      Map<String, dynamic> result;
      if (widget.article != null) {
        result = await _apiService.updateArticle(widget.article!.id, data);
      } else {
        result = await _apiService.createArticle(data);
      }

      setState(() => _isSubmitting = false);
      
      if (result['success']) {
        if (mounted) Navigator.pop(context, true);
      } else {
        _showErrorSnackBar(result['message'] ?? 'Gagal menyimpan artikel');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Terjadi kesalahan: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.article != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Artikel' : 'Tambah Artikel', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Artikel',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL Gambar (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.image),
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Konten Artikel',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Konten tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'Perbarui Artikel' : 'Simpan Artikel', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
