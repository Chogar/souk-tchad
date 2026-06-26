class ImageSearchResult {
  const ImageSearchResult({
    required this.keywords,
    this.primaryTerm,
    this.categoryHint,
  });

  final String keywords;
  final String? primaryTerm;
  final String? categoryHint;

  String get searchQuery {
    final parts = <String>{keywords.trim()};
    final primary = primaryTerm?.trim();
    if (primary != null && primary.isNotEmpty) {
      parts.add(primary);
    }
    return parts.join(' ');
  }

  factory ImageSearchResult.fromJson(Map<String, dynamic> json) {
    return ImageSearchResult(
      keywords: (json['keywords'] as String?)?.trim() ?? '',
      primaryTerm: (json['primaryTerm'] as String?)?.trim(),
      categoryHint: (json['categoryHint'] as String?)?.trim(),
    );
  }
}
