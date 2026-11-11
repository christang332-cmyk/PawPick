import 'package:flutter_test/flutter_test.dart';

import 'package:pawpick/domain/models/cart_item.dart';
import 'package:pawpick/domain/models/order.dart';

void main() {
  test('order JSON round trip preserves minor units and nested data', () {
    final order = Order(
      number: 'PP-2026-ABC123',
      items: const [
        CartItem(
          productId: 'pet-carrier',
          name: 'Pet carrier · Puffer tote',
          image: 'assets/images/products/travel/carrier_quilted_puffer_tote.jpg',
          unitPriceMinor: 280000,
          quantity: 2,
          styleId: 'puffer-tote',
        ),
      ],
      subtotalMinor: 560000,
      shippingMinor: 0,
      totalMinor: 560000,
      address: const Address(
        fullName: 'Biscuit Parent',
        phone: '+639171234567',
        line: '12 Paw Street',
        city: 'Manila',
        postalCode: '1000',
      ),
      paymentMethod: 'Cash on Delivery',
      createdAt: DateTime.utc(2026, 11, 11, 10),
    );

    final restored = Order.fromJson(order.toJson());

    expect(restored.number, order.number);
    expect(restored.totalMinor, 560000);
    expect(restored.createdAt, order.createdAt);
    expect(restored.items.single.styleId, 'puffer-tote');
    expect(restored.address.phone, '+639171234567');
  });
}
