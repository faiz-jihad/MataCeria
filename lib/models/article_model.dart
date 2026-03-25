// lib/models/article_model.dart

class Article {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? category;
  final String? date;

  Article({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.category,
    this.date,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'] ?? 'Tanpa Judul',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      category: json['category'],
      date: json['date'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'date': date,
    };
  }
}
