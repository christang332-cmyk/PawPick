import 'package:flutter_test/flutter_test.dart';

import 'package:pawpick/domain/models/cart_item.dart';
import 'package:pawpick/domain/models/order.dart';
import 'package:pawpick/features/orders/application/receipt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in [
    ('single item', [
      const CartItem(
        productId: 'test-1',
        name: 'Polka leather collar',
        image: 'assets/images/products/collars/collar_coach_polka_leather.jpg',
        unitPriceMinor: 350000,
        quantity: 1,
        variantId: 'variant-1',
        styleId: 'style-1',
        color: 'Pink',
        size: 'M',
      ),
    ]),
    ('ten items', [
      for (var i = 0; i < 10; i++)
        CartItem(
          productId: 'test-$i',
          name: 'Polka leather collar',
          image: 'assets/images/products/collars/collar_coach_polka_leather.jpg',
          unitPriceMinor: 350000,
          quantity: 1,
          variantId: 'variant-$i',
          styleId: 'style-$i',
          color: 'Pink',
          size: 'M',
        ),
    ]),
  ]) {
    test('builds receipt PDF for ${scenario.$1}', () async {
      final order = Order(
        number: 'PP-2026-ABC123',
        items: scenario.$2,
        subtotalMinor: scenario.$2.fold<int>(0, (sum, item) => sum + item.unitPriceMinor * item.quantity),
        shippingMinor: 0,
        totalMinor: scenario.$2.fold<int>(0, (sum, item) => sum + item.unitPriceMinor * item.quantity),
        address: const Address(
          fullName: 'Milo Pup',
          phone: '09171234567',
          line: '99 Bark Avenue',
          city: 'Quezon City',
          postalCode: '1101',
        ),
        paymentMethod: 'Cash on delivery',
        createdAt: DateTime(2026, 11, 10, 14, 30),
      );

      final bytes = await ReceiptPdfService.build(order);
      expect(bytes, isNotEmpty);
    });
  }
}
