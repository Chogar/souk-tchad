class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
  });

  final String id;
  final String name;
  final String slug;
  final String icon;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String? ?? '📦',
    );
  }

  Map<String, dynamic> toCacheJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
      };

  static List<Map<String, dynamic>> toCacheJsonList(
    Iterable<CategoryModel> categories,
  ) =>
      categories.map((c) => c.toCacheJson()).toList();
}
