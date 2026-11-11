import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/widgets/paw_widgets.dart';
import '../core/widgets/brand_logo.dart';
import '../core/notifications/app_notifier.dart';
import '../features/shop/application/shopping_providers.dart';
import '../features/shop/application/shop_filter_provider.dart';
import '../features/shop/presentation/shop_screens.dart';
import '../features/account/application/account_providers.dart';
import '../features/account/presentation/account_screens.dart';
import '../features/account/presentation/addresses_screen.dart';
import '../features/help/presentation/help_screen.dart';
import '../features/checkout/presentation/checkout_screens.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/orders/application/order_providers.dart';
import '../features/orders/presentation/receipt_preview_screen.dart';
import '../core/widgets/paw_confirm_dialog.dart';
import '../core/widgets/button_gallery_screen.dart';
import 'theme.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    final stream = Firebase.apps.isEmpty
        ? const Stream<User?>.empty()
        : FirebaseAuth.instance.authStateChanges();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: AppNotifier.navigatorKey,
    refreshListenable: _AuthRefreshNotifier(),
    redirect: (context, state) {
      if (state.matchedLocation == '/auth' &&
          _currentUser != null) {
        return '/home';
      }

      return null;
    },
    initialLocation: '/splash',
    observers: const [],
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            PawShell(navigationShell: navigationShell),
        branches: [
          _branch('/home', const HomeScreen()),
          _branch('/shop', const ShopScreen()),
          _branch('/favorites', const FavoritesScreen()),
          _branch('/cart', const CartScreen()),
          _branch('/account', const AccountScreen()),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success/:number',
        builder: (context, state) => OrderConfirmationScreen(
          number: state.pathParameters['number']!,
        ),
      ),
      GoRoute(
        path: '/order-confirmation/:number',
        builder: (context, state) => OrderConfirmationScreen(
          number: state.pathParameters['number']!,
        ),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/orders/:number',
        builder: (context, state) => OrderDetailScreen(
          number: state.pathParameters['number']!,
        ),
      ),
      GoRoute(
        path: '/receipt-preview/:number',
        builder: (context, state) {
          final number = state.pathParameters['number']!;
          final order = ProviderScope.containerOf(context, listen: false)
              .read(ordersProvider)
              .firstWhere((item) => item.number == number);
          return ReceiptPreviewScreen(order: order);
        },
      ),
      GoRoute(
        path: '/account/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/buttons',
          builder: (context, state) => const ButtonGalleryScreen(),
        ),
    ],
  );
});

User? get _currentUser =>
    Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

StatefulShellBranch _branch(String path, Widget child) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => child)],
  );
}

class PawShell extends ConsumerWidget {
  const PawShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider).fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index);
          if (index == 1) {
            ref.read(shopFilterProvider.notifier).clear();
            context.go('/shop');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 34, showWordmark: true),
          ],
        ),
        actions: [
          PawIconButton(
            tooltip: 'Search',
            size: 48,
            onPressed: () => ShopNavigator.open(
              ref,
              context,
              onlyNew: true,
            ),
            icon: Icons.search_rounded,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const PawChip(label: 'LITTLE THINGS. BIG JOY.'),
          const SizedBox(height: 12),
          Text('Joy, picked\nfor every paw.',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 10),
          Text(
            'Thoughtful accessories for your favorite companion.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Made for\nhappy tails.',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      const Text('Pet-safe picks, made to last.'),
                      const SizedBox(height: 18),
                      PawButton(
                        label: 'Explore picks',
                        onPressed: () => context.go('/shop'),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.cream,
                  child: Icon(Icons.pets_rounded,
                      size: 52, color: AppColors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Shop by category',
            onSeeAll: () => ShopNavigator.open(ref, context),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryTile(
                  label: 'Garments',
                  color: AppColors.pink,
                  icon: Icons.checkroom_rounded,
                  category: 'Garments',
                ),
                const SizedBox(width: 12),
                _CategoryTile(
                  label: 'Collars',
                  color: AppColors.sky,
                  icon: Icons.pets_rounded,
                  category: 'Collars & Harnesses',
                ),
                const SizedBox(width: 12),
                _CategoryTile(
                  label: 'Beds',
                  color: AppColors.palePink,
                  icon: Icons.bed_rounded,
                  category: 'Beds',
                ),
                const SizedBox(width: 12),
                _CategoryTile(
                  label: 'Feeding',
                  color: AppColors.yellow,
                  icon: Icons.restaurant_rounded,
                  category: 'Feeding',
                ),
                const SizedBox(width: 12),
                _CategoryTile(
                  label: 'Grooming',
                  color: AppColors.softGreen,
                  icon: Icons.brush_rounded,
                  category: 'Grooming',
                ),
                const SizedBox(width: 12),
                _CategoryTile(
                  label: 'Toys',
                  color: AppColors.yellow,
                  icon: Icons.toys_rounded,
                  category: 'Toys',
                ),
                const SizedBox(width: 12),
                _CategoryTile(
                  label: 'Travel',
                  color: AppColors.sky,
                  icon: Icons.luggage_rounded,
                  category: 'Travel',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    final products =
        ref.watch(catalogProvider).where((product) => ids.contains(product.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: products.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'Save the good stuff',
                message: 'Tap the heart on a product to keep it here.',
              ),
            )
          : GridView(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 18,
                mainAxisExtent: 320,
              ),
              children: products.map((product) => ProductCard(product: product)).toList(),
            ),
    );
  }
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    final orders = ref.watch(ordersProvider);
    final favorites = ref.watch(favoritesProvider);
    final displayName = account.name ?? 'PawPick friend';
    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Scaffold(
      appBar: AppBar(title: const Text('My PawPick')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.pink,
                  backgroundImage: account.photoUrl == null
                      ? null
                      : NetworkImage(account.photoUrl!),
                  child: account.photoUrl == null
                      ? Text(initials.isEmpty ? '🐾' : initials,
                          style: Theme.of(context).textTheme.titleLarge)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.isSignedIn ? displayName : 'Join the pack',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        account.isSignedIn
                            ? (account.email ?? 'Puppy tier')
                            : 'Save favorites and track every order.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _AccountStat(label: 'Orders', value: '${orders.length}'),
              const SizedBox(width: 8),
              _AccountStat(label: 'Favorites', value: '${favorites.length}'),
              const SizedBox(width: 8),
              const _AccountStat(label: 'Paw points', value: '0'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Your PawPick',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _AccountMenuTile(
            icon: Icons.receipt_long_rounded,
            title: 'My orders',
            subtitle: '${orders.length} saved order${orders.length == 1 ? '' : 's'}',
            onTap: () => context.push('/orders'),
          ),
          _AccountMenuTile(
            icon: Icons.favorite_rounded,
            title: 'Favorites',
            subtitle: 'Your saved little joys',
            onTap: () => context.go('/favorites'),
          ),
          _AccountMenuTile(
            icon: Icons.location_on_rounded,
            title: 'Addresses',
            subtitle: 'Manage delivery details',
            onTap: () => context.push('/account/addresses'),
          ),
          _AccountMenuTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & FAQ',
            subtitle: 'Friendly help for you and your pets',
            onTap: () => context.push('/help'),
          ),
          const SizedBox(height: 12),
          if (!account.isSignedIn)
            PawButton(
              label: 'Sign in or create account',
              onPressed: () => context.push('/auth'),
            )
          else
            PawButton(
              label: 'Sign out',
              isOutlined: true,
              onPressed: () async {
                final confirmed = await PawConfirmDialog.show(
                  context,
                  title: 'Sign out?',
                  message: 'Your guest bag will stay safe on this device.',
                  confirmLabel: 'Sign out',
                );
                if (!confirmed) return;
                await ref.read(accountProvider.notifier).signOut();
                if (context.mounted) AppNotifier.success('Signed out safely');
              },
            ),
        ],
      ),
    );
  }
}

class _AccountStat extends StatelessWidget {
  const _AccountStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          minVerticalPadding: 8,
          leading: CircleAvatar(
            backgroundColor: AppColors.palePink,
            foregroundColor: AppColors.blue,
            child: Icon(icon),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.category,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () => ShopNavigator.open(ref, context, category: category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 122,
          height: 118,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.ink),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
