// lib/models/article_model.dart

class Article {

  Article({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.shareUrl,
    this.category,
    this.date,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'] ?? 'Tanpa Judul',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      shareUrl: json['shareUrl'] ?? json['share_url'],
      category: json['category'],
      date: json['date'] ?? json['created_at'],
    );
  }
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? shareUrl;
  final String? category;
  final String? date;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'shareUrl': shareUrl,
      'category': category,
      'date': date,
    };
  }
}
