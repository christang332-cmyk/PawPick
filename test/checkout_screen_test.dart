import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpick/domain/models/cart_item.dart';
import 'package:pawpick/features/checkout/presentation/checkout_screens.dart';
import 'package:pawpick/features/shop/application/shopping_providers.dart';

void main() {
  testWidgets('checkout shows cart items and the complete price breakdown',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = [
      const CartItem(
        productId: 'sample-food',
        name: 'Sample food',
        image: '',
        unitPriceMinor: 175000,
        quantity: 2,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartProvider.overrideWith(() => _TestCartNotifier(items)),
        ],
        child: const MaterialApp(home: CheckoutScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review & place order'), findsOneWidget);
    expect(find.text('Your details'), findsOneWidget);
    expect(find.text('Sample food'), findsOneWidget);
    expect(find.text('Qty 2'), findsOneWidget);
    expect(_findPrice('₱3,500.00'), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(
      find.text('Deliver to'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Deliver to'), findsOneWidget);
    expect(find.text('Pay with'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Subtotal'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Shipping'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(_findPrice('₱3,500.00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Place order'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _findPrice(String amount) => find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().contains(amount),
    );

class _TestCartNotifier extends CartNotifier {
  _TestCartNotifier(this.items);

  final List<CartItem> items;

  @override
  List<CartItem> build() => items;
}
