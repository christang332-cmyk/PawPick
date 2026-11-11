enum ProductType { general, garment }

enum ProductCategory { garments, collarsHarnesses, beds, feeding, grooming, toys, travel }

extension ProductCategoryX on ProductCategory {
  String get slug {
    switch (this) {
      case ProductCategory.garments:
        return 'garments';
      case ProductCategory.collarsHarnesses:
        return 'collars-harnesses';
      case ProductCategory.beds:
        return 'beds';
      case ProductCategory.feeding:
        return 'feeding';
      case ProductCategory.grooming:
        return 'grooming';
      case ProductCategory.toys:
        return 'toys';
      case ProductCategory.travel:
        return 'travel';
    }
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.colorName,
    required this.colorHex,
    required this.size,
    required this.stock,
  });

  final String id;
  final String colorName;
  final int colorHex;
  final String size;
  final int stock;
}

class ProductStyle {
  const ProductStyle({
    required this.id,
    required this.label,
    required this.image,
    required this.priceMinor,
    this.stock = 10,
  });

  final String id;
  final String label;
  final String image;
  final int priceMinor;
  final int stock;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    required this.priceMinor,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    this.originalPriceMinor,
    this.badge,
    this.variants = const [],
    this.styles = const [],
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final ProductType type;
  final int priceMinor;
  final int? originalPriceMinor;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final int stock;
  final String? badge;
  final List<ProductVariant> variants;
  final List<ProductStyle> styles;

  int get lowestPriceMinor => styles.isEmpty
      ? priceMinor
      : styles.map((style) => style.priceMinor).reduce((a, b) => a < b ? a : b);

  bool get isOnSale => originalPriceMinor != null;
  bool get isOutOfStock => type == ProductType.garment
      ? variants.every((variant) => variant.stock == 0)
      : stock == 0;
}
