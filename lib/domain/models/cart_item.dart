class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.unitPriceMinor,
    required this.quantity,
    this.variantId,
    this.styleId,
    this.color,
    this.size,
  });

  final String productId;
  final String name;
  final String image;
  final int unitPriceMinor;
  final int quantity;
  final String? variantId;
  final String? styleId;
  final String? color;
  final String? size;

  String get key =>
      '$productId:${styleId ?? 'default'}:${variantId ?? 'default'}:${color ?? ''}:${size ?? ''}';

  CartItem copyWith({int? quantity, int? unitPriceMinor}) => CartItem(
        productId: productId,
        name: name,
        image: image,
        unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
        quantity: quantity ?? this.quantity,
        variantId: variantId,
        styleId: styleId,
        color: color,
        size: size,
      );
}
