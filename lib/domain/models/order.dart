import 'cart_item.dart';

class Address {
  const Address({
    required this.fullName,
    required this.phone,
    required this.line,
    required this.city,
    required this.postalCode,
  });

  final String fullName;
  final String phone;
  final String line;
  final String city;
  final String postalCode;

  String get label => '$line, $city $postalCode';

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'line': line,
        'city': city,
        'postalCode': postalCode,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        line: json['line'] as String,
        city: json['city'] as String,
        postalCode: json['postalCode'] as String,
      );
}

enum OrderStatus { placed, packed, shipped, outForDelivery, delivered, cancelled }

class Order {
  const Order({
    required this.number,
    required this.items,
    required this.subtotalMinor,
    required this.shippingMinor,
    required this.totalMinor,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
    this.status = OrderStatus.placed,
    this.cancelReason,
    this.cancelledAt,
    this.synced = false,
  });

  final String number;
  final List<CartItem> items;
  final int subtotalMinor;
  final int shippingMinor;
  final int totalMinor;
  final Address address;
  final String paymentMethod;
  final DateTime createdAt;
  final OrderStatus status;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final bool synced;

  Map<String, dynamic> toJson() => {
        'number': number,
        'items': items
            .map((item) => {
                  'productId': item.productId,
                  'name': item.name,
                  'image': item.image,
                  'price': item.unitPriceMinor,
                  'quantity': item.quantity,
                  'variantId': item.variantId,
                  'styleId': item.styleId,
                  'color': item.color,
                  'size': item.size,
                })
            .toList(),
        'subtotalMinor': subtotalMinor,
        'shippingMinor': shippingMinor,
        'totalMinor': totalMinor,
        'address': address.toJson(),
        'paymentMethod': paymentMethod,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'cancelReason': cancelReason,
        'cancelledAt': cancelledAt?.toIso8601String(),
        'synced': synced,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        number: json['number'] as String,
        items: (json['items'] as List<dynamic>)
            .map((item) {
              final map = item as Map<String, dynamic>;
              return CartItem(
                productId: map['productId'] as String,
                name: map['name'] as String,
                image: map['image'] as String,
                unitPriceMinor: map['price'] as int,
                quantity: map['quantity'] as int,
                variantId: map['variantId'] as String?,
                styleId: map['styleId'] as String?,
                color: map['color'] as String?,
                size: map['size'] as String?,
              );
            })
            .toList(growable: false),
        subtotalMinor: json['subtotalMinor'] as int,
        shippingMinor: json['shippingMinor'] as int,
        totalMinor: json['totalMinor'] as int,
        address: Address.fromJson(json['address'] as Map<String, dynamic>),
        paymentMethod: json['paymentMethod'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: OrderStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => OrderStatus.placed,
        ),
            cancelReason: json['cancelReason'] as String?,
            cancelledAt: json['cancelledAt'] == null
                ? null
                : DateTime.tryParse(json['cancelledAt'] as String),
        synced: json['synced'] as bool? ?? false,
      );
}
