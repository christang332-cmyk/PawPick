import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/cart_item.dart';
import '../domain/models/order.dart';

class LocalStore {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    if (!_preferences!.containsKey('guest_device_id')) {
      await _preferences!.setString(
        'guest_device_id',
        DateTime.now().microsecondsSinceEpoch.toString(),
      );
    }
  }

  static String get guestScope =>
      'guest:${_preferences?.getString('guest_device_id') ?? 'device'}';

  static List<CartItem> readCart(String scope) {
    final raw = _preferences?.getStringList('cart_$scope') ?? [];
    return raw.map((entry) {
      final map = jsonDecode(entry) as Map<String, dynamic>;
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
    }).toList();
  }

  static void writeCart(String scope, List<CartItem> items) {
    _preferences?.setStringList(
      'cart_$scope',
      items
          .map((item) => jsonEncode({
                'productId': item.productId,
                'name': item.name,
                'image': item.image,
                'price': item.unitPriceMinor,
                'quantity': item.quantity,
                'variantId': item.variantId,
                'styleId': item.styleId,
                'color': item.color,
                'size': item.size,
              }))
          .toList(),
    );
  }

  static List<Order> readOrders(String ownerKey) {
    final raw = _preferences?.getStringList('orders_$ownerKey') ?? [];
    return raw
        .map((entry) => Order.fromJson(
            Map<String, dynamic>.from(jsonDecode(entry) as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> writeOrders(String ownerKey, List<Order> orders) async {
    await _preferences?.setStringList(
      'orders_$ownerKey',
      orders.map((order) => jsonEncode(order.toJson())).toList(),
    );
  }

  static Set<String> readFavorites(String scope) =>
      (_preferences?.getStringList('favorites_$scope') ?? []).toSet();

  static void writeFavorites(String scope, Set<String> ids) =>
      _preferences?.setStringList('favorites_$scope', ids.toList());

  static void mergeGuestData(String userScope) {
    final guest = guestScope;
    final guestOrders = readOrders(guest);
    final userOrders = readOrders(userScope);
    if (guestOrders.isNotEmpty) {
      _preferences?.setStringList(
        'orders_$userScope',
        [...guestOrders, ...userOrders]
            .map((order) => jsonEncode(order.toJson()))
            .toList(),
      );
      _preferences?.remove('orders_$guest');
    }
    final guestCart = readCart(guest);
    final userCart = readCart(userScope);
    final merged = [...userCart];
    for (final item in guestCart) {
      final index = merged.indexWhere((entry) => entry.key == item.key);
      if (index == -1) {
        merged.add(item.copyWith(quantity: item.quantity > 10 ? 10 : item.quantity));
      } else {
        final quantity = merged[index].quantity + item.quantity;
        merged[index] = merged[index].copyWith(
          quantity: quantity > 10 ? 10 : quantity,
        );
      }
    }
    writeCart(userScope, merged);
    _preferences?.remove('cart_$guest');
    _preferences?.remove('favorites_$guest');
  }

  static bool get onboardingComplete =>
      _preferences?.getBool('onboarding_complete') ?? false;

  static Future<void> completeOnboarding() async {
    await _preferences?.setBool('onboarding_complete', true);
  }

  static Address? readDefaultAddress(String ownerKey) {
    final raw = _preferences?.getString('default_address_$ownerKey');
    if (raw == null) return null;
    return Address.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  static Future<void> writeDefaultAddress(
    String ownerKey,
    Address address,
  ) async {
    await _preferences?.setString(
      'default_address_$ownerKey',
      jsonEncode(address.toJson()),
    );
  }

  static String readPaymentMethod(String ownerKey) =>
      _preferences?.getString('payment_method_$ownerKey') ??
      'Cash on Delivery';

  static Future<void> writePaymentMethod(
    String ownerKey,
    String paymentMethod,
  ) async {
    await _preferences?.setString('payment_method_$ownerKey', paymentMethod);
  }
}
