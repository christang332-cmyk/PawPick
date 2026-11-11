import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/paw_widgets.dart';
import '../../../core/widgets/animated/animated_widgets.dart';
import '../../../core/utils/money.dart';
import '../../../core/notifications/app_notifier.dart';
import '../../../core/widgets/paw_confirm_dialog.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/product.dart';
import '../application/shopping_providers.dart';
import '../application/shop_filter_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _queryApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_queryApplied) return;
    final params = GoRouterState.of(context).uri.queryParameters;
    final slug = params['category'];
    final notifier = ref.read(shopFilterProvider.notifier);
    if (slug != null) {
      notifier.replace(category: _categoryFromSlug(slug));
    } else if (params['filter'] == 'featured') {
      notifier.replace(onlyNew: true);
    }
    _queryApplied = true;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(catalogProvider);
    final filter = ref.watch(shopFilterProvider);
    final availableCategories = all.map((product) => product.category).toSet();
    final effectiveCategory =
        filter.category != 'All' && !availableCategories.contains(filter.category)
            ? 'All'
            : filter.category;
    if (effectiveCategory != filter.category) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(shopFilterProvider.notifier).clear();
        AppNotifier.info('Showing all picks',
            message: 'That category is not available right now.');
      });
    }
    final shown = all.where((product) {
      final matchesQuery =
          product.name.toLowerCase().contains(filter.query.toLowerCase());
      final matchesCategory =
          effectiveCategory == 'All' || product.category == effectiveCategory;
      final matchesSale = !filter.onlyOnSale || product.isOnSale;
      return matchesQuery && matchesCategory && matchesSale;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop', style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          PawIconButton(
            tooltip: 'Filter',
            size: 48,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => _FilterSheet(
                selected: effectiveCategory,
                categories: availableCategories.toList()..sort(),
                onSelected: (value) {
                  ref.read(shopFilterProvider.notifier).replace(category: value);
                  Navigator.pop(context);
                },
              ),
            ),
            icon: Icons.tune_rounded,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: TextField(
              onChanged: (value) =>
                  ref.read(shopFilterProvider.notifier).replace(
                        category: filter.category,
                        query: value,
                      ),
              decoration: const InputDecoration(
                hintText: 'Search collars, toys, beds...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? const Center(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No picks found',
                      message: 'Try a different search or category.',
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 18,
                      mainAxisExtent: 320,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (_, index) => StaggeredEntrance(
                      index: index,
                      child: ProductCard(product: shown[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _categoryFromSlug(String slug) {
    switch (slug) {
      case 'garments':
      case 'Garments':
        return 'Garments';
      case 'collars-harnesses':
      case 'Collars & Harnesses':
        return 'Collars & Harnesses';
      case 'beds':
      case 'Beds':
        return 'Beds';
      case 'feeding':
      case 'Feeding':
        return 'Feeding';
      case 'grooming':
      case 'Grooming':
        return 'Grooming';
      case 'toys':
      case 'Toys':
        return 'Toys';
      case 'travel':
      case 'Travel':
        return 'Travel';
      default:
        return 'All';
    }
  }
}

class ProductCard extends ConsumerWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(product.id);
    return PressScale(
      onPressed: () => context.push('/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Hero(
                    tag: 'product-image-${product.id}',
                    child: CachedPawImage(
                      url: product.images.first,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              if (product.badge != null)
                Positioned(
                  left: 8,
                  top: 8,
                  child: PawChip(label: product.badge!, color: AppColors.blue),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: PawIconButton(
                  tooltip: 'Favorite',
                  size: 40,
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(product.id),
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  variant: isFavorite
                      ? PawButtonVariant.danger
                      : PawButtonVariant.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(context).textTheme.labelLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          PriceText(
            amount: product.lowestPriceMinor,
            originalAmount: product.originalPriceMinor,
          ),
          const SizedBox(height: 2),
          Text(
            '★ ${product.rating} (${product.reviewCount})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductVariant? selectedVariant;
  ProductStyle? selectedStyle;
  int quantity = 1;
  bool _addingToCart = false;
  bool _justAddedToCart = false;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(catalogProvider).firstWhere(
          (item) => item.id == widget.productId,
        );
    final variants = product.variants;
    final max = selectedStyle?.stock ?? selectedVariant?.stock ?? product.stock;
    final selectedPrice = selectedStyle?.priceMinor ?? product.priceMinor;
    final galleryImages = [
      if (selectedStyle != null) selectedStyle!.image,
      ...product.images.where((image) => image != selectedStyle?.image),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          PawIconButton(
            tooltip: 'Share',
            size: 48,
            onPressed: () {},
            icon: Icons.share_rounded,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cream,
            border: const Border(top: BorderSide(color: AppColors.line)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 52,
                child: QuantityStepper(
                  value: quantity,
                  max: max.clamp(1, 10),
                  onDecrement: quantity > 1
                      ? () => setState(() {
                            quantity--;
                            _justAddedToCart = false;
                          })
                      : null,
                  onIncrement: quantity < max.clamp(1, 10)
                      ? () => setState(() {
                            quantity++;
                            _justAddedToCart = false;
                          })
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PawButton(
                  height: 52,
                  isLoading: _addingToCart,
                  icon: _justAddedToCart ? Icons.check_rounded : null,
                  label: _justAddedToCart ? 'Added to bag' : 'Add to cart',
                  labelWidget: _justAddedToCart
                      ? null
                      : Text.rich(
                          Money.template(
                            'Add to cart · {amount}',
                            selectedPrice * quantity,
                            Theme.of(context).textTheme.labelLarge,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                        ),
                  onPressed: () async {
                    if (_addingToCart) return;
                    if (product.type == ProductType.garment &&
                        selectedVariant == null) {
                      AppNotifier.warning('Choose a color and size first.');
                      return;
                    }
                    if (product.styles.isNotEmpty && selectedStyle == null) {
                      AppNotifier.warning('Choose a style first.');
                      return;
                    }
                    setState(() {
                      _addingToCart = true;
                      _justAddedToCart = false;
                    });
                    await Future<void>.delayed(Duration.zero);
                    if (!mounted) return;
                    String? message;
                    for (var i = 0; i < quantity; i++) {
                      message = ref
                          .read(cartProvider.notifier)
                          .add(product, variant: selectedVariant, style: selectedStyle);
                      if (message != null) break;
                    }
                    setState(() {
                      _addingToCart = false;
                      _justAddedToCart = message == null;
                    });
                    if (message == null) {
                      AppNotifier.success(
                        'Added to your bag',
                        message: 'A little joy is on its way.',
                        actionLabel: 'View cart',
                        onAction: () => context.go('/cart'),
                      );
                    } else {
                      AppNotifier.warning(message);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 76 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SizedBox(
            height: 330,
            child: PageView(
              children: galleryImages
                  .map(
                    (url) => Hero(
                      tag: url == product.images.first
                          ? 'product-image-${product.id}'
                          : 'gallery-${product.id}-$url',
                      child: CachedPawImage(
                        url: url,
                        width: double.infinity,
                        height: 330,
                        borderRadius: 0,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.badge != null) PawChip(label: product.badge!),
                const SizedBox(height: 10),
                Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('★ ${product.rating} · ${product.reviewCount} reviews',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                PriceText(
                  amount: selectedPrice,
                  originalAmount: product.originalPriceMinor,
                ),
                const SizedBox(height: 18),
                Text(product.description),
                if (product.styles.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Choose your style',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: product.styles
                        .map((style) => ChoiceChip(
                              label: Text(style.label),
                              selected: selectedStyle?.id == style.id,
                              onSelected: style.stock == 0
                                  ? null
                                  : (_) => setState(() {
                                        selectedStyle = style;
                                        quantity = 1;
                                      }),
                            ))
                        .toList(),
                  ),
                ],
                if (product.type == ProductType.garment) ...[
                  const SizedBox(height: 24),
                  Text('Choose a color and size',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: variants
                        .map(
                          (variant) => ChoiceChip(
                            label: Text('${variant.colorName} · ${variant.size}'),
                            selected: selectedVariant?.id == variant.id,
                            onSelected: variant.stock == 0
                                ? null
                                : (_) => setState(() {
                                      selectedVariant = variant;
                                      quantity = 1;
                                    }),
                          ),
                        )
                        .toList(),
                  ),
                  if (selectedVariant != null && selectedVariant!.stock <= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('Only ${selectedVariant!.stock} left',
                          style: const TextStyle(color: AppColors.blue)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final subtotal = cart.subtotalMinor;
    final shipping = subtotal >= 250000 || subtotal == 0 ? 0 : 4900;
    final total = subtotal + shipping;
    return Scaffold(
      appBar: AppBar(title: Text('Your bag', style: Theme.of(context).textTheme.headlineSmall)),
      body: items.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Your bag is waiting',
                message: 'Add something joyful for your favorite companion.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                ...items.map(
                  (item) => _CartLine(
                    item: item,
                    onMinus: () async {
                      if (item.quantity == 1) {
                        final confirmed = await PawConfirmDialog.show(
                          context,
                          title: 'Remove this pick?',
                          message: 'Remove this item from your bag?',
                        );
                        if (confirmed) {
                          ref.read(cartProvider.notifier).remove(item);
                          AppNotifier.success('Removed from your bag',
                              actionLabel: 'Undo',
                              onAction: () => ref.read(cartProvider.notifier).restore(item));
                        }
                      } else {
                        ref.read(cartProvider.notifier).decrement(item);
                      }
                    },
                    onPlus: () => ref.read(cartProvider.notifier).increment(item),
                    onRemove: () async {
                      final confirmed = await PawConfirmDialog.show(
                        context,
                        title: 'Remove this pick?',
                        message: 'Remove this item from your bag?',
                      );
                      if (confirmed) {
                        ref.read(cartProvider.notifier).remove(item);
                        AppNotifier.success('Removed from your bag',
                            actionLabel: 'Undo',
                            onAction: () => ref.read(cartProvider.notifier).restore(item));
                      }
                    },
                  ),
                ),
                const Divider(height: 32),
                if (subtotal < 250000)
                  Text.rich(
                    Money.template(
                      'Add {amount} more for free shipping',
                      250000 - subtotal,
                      Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                const SizedBox(height: 16),
                _SummaryRow(label: 'Subtotal', amount: subtotal),
                _SummaryRow(
                  label: 'Shipping',
                  amount: shipping == 0 ? null : shipping,
                  value: shipping == 0 ? 'FREE' : null,
                ),
                const Divider(),
                _SummaryRow(label: 'Total', amount: total, isTotal: true),
                const SizedBox(height: 16),
                PawButton(
                  label: 'Proceed to checkout',
                  onPressed: () => context.push('/checkout'),
                ),
              ],
            ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item, required this.onMinus, required this.onPlus, required this.onRemove});

  final CartItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _CartImage(item.image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.labelLarge),
                if (item.color != null) Text('${item.color} · ${item.size}'),
                const SizedBox(height: 5),
                PriceText(
                  amount: item.unitPriceMinor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                QuantityStepper(value: item.quantity, onDecrement: onMinus, onIncrement: onPlus),
              ],
            ),
          ),
          PawIconButton(
            tooltip: 'Remove item',
            variant: PawButtonVariant.danger,
            onPressed: onRemove,
            icon: Icons.delete_outline_rounded,
          ),
        ],
      ),
    );
  }

}

class _CartImage extends StatelessWidget {
  const _CartImage(this.path);

  final String path;

  @override
  Widget build(BuildContext context) {
    final fallback = const ColoredBox(
      color: AppColors.palePink,
      child: SizedBox(
        width: 82,
        height: 82,
        child: Icon(Icons.pets_rounded),
      ),
    );
    return path.startsWith('http')
        ? Image.network(path,
            width: 82, height: 82, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback)
        : Image.asset(path,
            width: 82, height: 82, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    this.value,
    this.amount,
    this.isTotal = false,
  });

  final String label;
  final String? value;
  final int? amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          if (amount != null)
            PriceText(amount: amount, style: style)
          else
            Text(value ?? '', style: style),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.selected,
    required this.categories,
    required this.onSelected,
  });

  final String selected;
  final List<String> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = ['All', ...categories];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 8,
          children: options
              .map((category) => ChoiceChip(
                    label: Text(category),
                    selected: selected == category,
                    onSelected: (_) => onSelected(category),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
