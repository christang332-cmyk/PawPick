import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawpick/data/seed_data.dart';
import 'package:pawpick/features/shop/application/shopping_providers.dart';
import 'package:pawpick/domain/models/cart_item.dart';

void main() {
  test('cart merges a product and caps it at ten units', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(cartProvider.notifier);
    notifier.clear();

    for (var index = 0; index < 10; index++) {
      expect(notifier.add(products[1]), isNull);
    }

    expect(container.read(cartProvider).single.quantity, 10);
    expect(
      notifier.add(products[1]),
      'Max 10 per item, so everyone gets a turn 🐾',
    );
  });

  test('garment variants remain separate cart lines', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(cartProvider.notifier);
    notifier.clear();
    final product = products.first;

    notifier.add(product, variant: product.variants[0]);
    notifier.add(product, variant: product.variants[1]);

    expect(container.read(cartProvider), hasLength(2));
  });

  test('saved cart lines use current catalog and style prices', () {
    final styleProduct =
        products.firstWhere((product) => product.id == 'pet-carrier');
    final legacyItems = [
      CartItem(
        productId: 'dog-strawberry-sweater',
        name: 'Strawberry sweater',
        image: 'sweater.jpg',
        unitPriceMinor: 150000,
        quantity: 2,
      ),
      CartItem(
        productId: styleProduct.id,
        name: 'Pet carrier · Pink glitter purse',
        image: 'carrier.jpg',
        unitPriceMinor: 500000,
        quantity: 1,
        styleId: 'glitter-purse',
      ),
      CartItem(
        productId: 'removed-product',
        name: 'Old item',
        image: 'old.jpg',
        unitPriceMinor: 30000,
        quantity: 1,
      ),
    ];

    final updatedItems = repriceCartItems(legacyItems, products);

    expect(updatedItems[0].unitPriceMinor, 99900);
    expect(updatedItems[0].quantity, 2);
    expect(updatedItems[1].unitPriceMinor, 450000);
    expect(updatedItems[2].unitPriceMinor, 30000);
  });

  test('multi-style products start at their lowest listed option price', () {
    for (final product in products.where((entry) => entry.styles.isNotEmpty)) {
      final lowestStylePrice = product.styles
          .map((style) => style.priceMinor)
          .reduce((first, second) => first < second ? first : second);
      expect(product.priceMinor, lowestStylePrice, reason: product.id);
    }
  });
}
