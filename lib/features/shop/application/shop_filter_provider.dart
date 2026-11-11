import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class ShopFilterState {
  const ShopFilterState({
    this.category = 'All',
    this.query = '',
    this.onlyNew = false,
    this.onlyOnSale = false,
  });

  final String category;
  final String query;
  final bool onlyNew;
  final bool onlyOnSale;

  ShopFilterState copyWith({
    String? category,
    String? query,
    bool? onlyNew,
    bool? onlyOnSale,
  }) =>
      ShopFilterState(
        category: category ?? this.category,
        query: query ?? this.query,
        onlyNew: onlyNew ?? this.onlyNew,
        onlyOnSale: onlyOnSale ?? this.onlyOnSale,
      );
}

final shopFilterProvider =
    NotifierProvider<ShopFilterNotifier, ShopFilterState>(
  ShopFilterNotifier.new,
);

class ShopFilterNotifier extends Notifier<ShopFilterState> {
  @override
  ShopFilterState build() => const ShopFilterState();

  void replace({
    String category = 'All',
    String query = '',
    bool onlyNew = false,
    bool onlyOnSale = false,
  }) {
    state = ShopFilterState(
      category: category,
      query: query,
      onlyNew: onlyNew,
      onlyOnSale: onlyOnSale,
    );
  }

  void clear() => replace();
}

abstract final class ShopNavigator {
  static void open(
    WidgetRef ref,
    BuildContext context, {
    String category = 'All',
    bool onlyNew = false,
    bool onlyOnSale = false,
  }) {
    ref.read(shopFilterProvider.notifier).replace(
          category: category,
          onlyNew: onlyNew,
          onlyOnSale: onlyOnSale,
        );
    context.go('/shop');
  }
}
