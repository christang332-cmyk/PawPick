import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/order.dart';
import '../../../domain/models/cart_item.dart';
import '../../../data/firestore_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../shop/application/shopping_providers.dart';
import '../../account/application/account_providers.dart';
import '../../../data/local_store.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../data/seed_data.dart';
import '../../../domain/models/product.dart';

final ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    ref.watch(accountProvider);
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    final scope = user?.uid ?? LocalStore.guestScope;
    if (user != null) LocalStore.mergeGuestData(user.uid);
    return LocalStore.readOrders(scope);
  }

  Future<Order> placeOrder({
    required List<CartItem> cart,
    required Address address,
    required String paymentMethod,
    required int shippingMinor,
  }) async {
    final subtotal =
        cart.fold<int>(0, (total, item) => total + item.unitPriceMinor * item.quantity);
    final order = Order(
      number: 'PP-${DateTime.now().year}-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      items: List.unmodifiable(cart),
      subtotalMinor: subtotal,
      shippingMinor: shippingMinor,
      totalMinor: subtotal + shippingMinor,
      address: address,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    final ownerKey = user?.uid ?? LocalStore.guestScope;
    final nextOrders = [order, ...state];
    try {
      await LocalStore.writeOrders(ownerKey, nextOrders);
    } catch (error, stackTrace) {
      debugPrint('Local order save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    state = nextOrders;
    ref.read(cartProvider.notifier).clear();
    if (user != null) {
      unawaited(_syncOrder(user.uid, order));
    }
    return order;
  }

  Future<void> cancelOrder(
    Order order, {
    required String reason,
    String? note,
  }) async {
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    final ownerKey = user?.uid ?? LocalStore.guestScope;
    final nextOrders = state.map((entry) {
      if (entry.number != order.number) return entry;
      final details = note == null || note.trim().isEmpty ? reason : '$reason — $note';
      return Order(
        number: entry.number,
        items: entry.items,
        subtotalMinor: entry.subtotalMinor,
        shippingMinor: entry.shippingMinor,
        totalMinor: entry.totalMinor,
        address: entry.address,
        paymentMethod: entry.paymentMethod,
        createdAt: entry.createdAt,
        status: OrderStatus.cancelled,
        cancelReason: details,
        cancelledAt: DateTime.now(),
        synced: entry.synced,
      );
    }).toList();

    await LocalStore.writeOrders(ownerKey, nextOrders);
    state = nextOrders;
    debugPrint('Order ${order.number} cancelled: $reason');
  }

  Future<int> buyAgain(Order order) async {
    var added = 0;
    for (final item in order.items) {
      final product = _productById(item.productId);
      if (product == null) continue;
      final variant = product.variants.firstWhere(
        (entry) => entry.id == item.variantId,
        orElse: () => const ProductVariant(
          id: '',
          colorName: '',
          colorHex: 0,
          size: '',
          stock: 0,
        ),
      );
      final style = product.styles.firstWhere(
        (entry) => entry.id == item.styleId,
        orElse: () => const ProductStyle(
          id: '',
          label: '',
          image: '',
          priceMinor: 0,
          stock: 0,
        ),
      );
      final available = style.id.isEmpty
          ? (variant.id.isEmpty ? product.stock : variant.stock)
          : style.stock;
      if (available <= 0) continue;
      final message = ref.read(cartProvider.notifier).add(
        product,
        variant: variant.id.isEmpty ? null : variant,
        style: style.id.isEmpty ? null : style,
      );
      if (message == null) {
        added++;
      }
    }
    return added;
  }

  Product? _productById(String id) {
    final alias = productIdAliases[id] ?? id;
    for (final product in products) {
      if (product.id == alias) return product;
    }
    return null;
  }

  Future<void> _syncOrder(String uid, Order order) async {
    try {
      await firestoreRepository.saveOrder(uid, order);
      debugPrint('Order ${order.number} synced to Firestore.');
    } catch (error, stackTrace) {
      debugPrint('Background order sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
