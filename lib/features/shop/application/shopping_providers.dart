import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../data/seed_data.dart';
import '../../../data/local_store.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/product.dart';
import '../../account/application/account_providers.dart';

final catalogProvider = Provider<List<Product>>((ref) => products);

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

String get currentStorageScope => Firebase.apps.isNotEmpty
    ? FirebaseAuth.instance.currentUser?.uid ?? LocalStore.guestScope
    : LocalStore.guestScope;

class CartNotifier extends Notifier<List<CartItem>> {
  static const maxQuantity = 10;

  @override
  List<CartItem> build() {
    ref.watch(accountProvider);
    final scope = currentStorageScope;
    final storedItems = LocalStore.readCart(scope);
    final catalog = ref.watch(catalogProvider);
    final currentItems = repriceCartItems(storedItems, catalog);
    if (!_samePrices(storedItems, currentItems)) {
      LocalStore.writeCart(scope, currentItems);
    }
    return currentItems;
  }

  String? add(Product product, {ProductVariant? variant, ProductStyle? style}) {
    if (product.isOutOfStock || (variant != null && variant.stock == 0)) {
      return 'This pick is currently out of stock.';
    }
    final key =
        '${product.id}:${style?.id ?? 'default'}:${variant?.id ?? 'default'}:${variant?.colorName ?? ''}:${variant?.size ?? ''}';
    final index = state.indexWhere((item) => item.key == key);
    final current = index == -1 ? 0 : state[index].quantity;
    final available = style?.stock ?? variant?.stock ?? product.stock;
    final limit = available < maxQuantity ? available : maxQuantity;
    if (current >= limit) {
      return available < maxQuantity
          ? 'Only $available left in stock.'
          : 'Max 10 per item, so everyone gets a turn 🐾';
    }
    final item = CartItem(
      productId: product.id,
      name: style == null ? product.name : '${product.name} · ${style.label}',
      image: style?.image ??
          (variant?.id == null ? product.images.first : variantImage(product, variant!)),
      unitPriceMinor: style?.priceMinor ?? product.priceMinor,
      quantity: current + 1,
      variantId: variant?.id,
      styleId: style?.id,
      color: variant?.colorName,
      size: variant?.size,
    );
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) item else state[i],
      if (index == -1) item,
    ];
    LocalStore.writeCart(_scope, state);
    return null;
  }

  void increment(CartItem item) {
    if (item.quantity < maxQuantity) {
      state = state
          .map((entry) => entry.key == item.key
              ? entry.copyWith(quantity: entry.quantity + 1)
              : entry)
          .toList();
      LocalStore.writeCart(_scope, state);
    }
  }

  void decrement(CartItem item) {
    if (item.quantity > 1) {
      state = state
          .map((entry) => entry.key == item.key
              ? entry.copyWith(quantity: entry.quantity - 1)
              : entry)
          .toList();
      LocalStore.writeCart(_scope, state);
    } else {
      remove(item);
    }
  }

  void remove(CartItem item) {
    state = state.where((entry) => entry.key != item.key).toList();
    LocalStore.writeCart(_scope, state);
  }

  void restore(CartItem item) {
    if (state.any((entry) => entry.key == item.key)) return;
    state = [...state, item];
    LocalStore.writeCart(_scope, state);
  }

  void clear() {
    state = [];
    LocalStore.writeCart(_scope, const []);
  }

  int get subtotalMinor =>
      state.fold(0, (total, item) => total + item.unitPriceMinor * item.quantity);

  String get _scope => currentStorageScope;
}

List<CartItem> repriceCartItems(
  List<CartItem> items,
  List<Product> catalog,
) =>
    items.map((item) {
      Product? product;
      for (final entry in catalog) {
        if (entry.id == item.productId) {
          product = entry;
          break;
        }
      }
      if (product == null) return item;

      final styleId = item.styleId;
      if (styleId == null) {
        return item.copyWith(unitPriceMinor: product.priceMinor);
      }
      for (final style in product.styles) {
        if (style.id == styleId) {
          return item.copyWith(unitPriceMinor: style.priceMinor);
        }
      }
      return item;
    }).toList();

bool _samePrices(List<CartItem> first, List<CartItem> second) {
  for (var index = 0; index < first.length; index++) {
    if (first[index].unitPriceMinor != second[index].unitPriceMinor) {
      return false;
    }
  }
  return true;
}

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(accountProvider);
    final scope = currentStorageScope;
    return LocalStore.readFavorites(scope);
  }

  void toggle(String productId) {
    final next = {...state};
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = next;
    final scope = currentStorageScope;
    LocalStore.writeFavorites(scope, state);
  }
}

String variantImage(Product product, ProductVariant variant) =>
    product.images[variant.colorHex % product.images.length];
