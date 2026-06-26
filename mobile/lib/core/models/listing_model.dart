import 'category_model.dart';
import 'user_model.dart';

class ListingModel {
  const ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.city,
    required this.images,
    this.videos = const [],
    required this.status,
    required this.category,
    required this.user,
    required this.createdAt,
    this.customCategoryName,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String city;
  final List<String> images;
  final List<String> videos;
  final String status;
  final CategoryModel category;
  final UserModel user;
  final DateTime createdAt;
  final String? customCategoryName;

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: double.parse(json['price'].toString()),
      currency: json['currency'] as String? ?? 'XAF',
      city: json['city'] as String? ?? "N'Djamena",
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      status: json['status'] as String? ?? 'ACTIVE',
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : CategoryModel(
              id: json['categoryId'] as String? ?? '',
              name: 'Catégorie',
              slug: '',
              icon: '📦',
            ),
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : UserModel(
              id: json['userId'] as String? ?? '',
              email: '',
              name: 'Utilisateur',
              plan: 'FREE',
              isEmailVerified: true,
            ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      customCategoryName: json['customCategoryName'] as String?,
    );
  }
}
