import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/notifications/app_notifier.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/paw_widgets.dart';
import '../../../data/local_store.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/order.dart';
import '../../orders/application/order_providers.dart';
import '../../shop/application/shopping_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final List<CartItem> snapshot;
  late final String ownerKey;
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController line;
  late final TextEditingController city;
  late final TextEditingController postal;
  String payment = 'Cash on Delivery';
  bool isPlacing = false;
  bool gift = false;
  bool _promptShown = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    snapshot = List.unmodifiable(ref.read(cartProvider));
    ownerKey = _user?.uid ?? 'guest';
    final savedAddress = LocalStore.readDefaultAddress(ownerKey);
    final nameValue = savedAddress?.fullName ?? _user?.displayName ?? '';
    name = TextEditingController(text: nameValue);
    phone = TextEditingController(text: savedAddress?.phone ?? '');
    line = TextEditingController(text: savedAddress?.line ?? '');
    city = TextEditingController(text: savedAddress?.city ?? '');
    postal = TextEditingController(text: savedAddress?.postalCode ?? '');
    payment = LocalStore.readPaymentMethod(ownerKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (snapshot.isEmpty) {
        AppNotifier.info('Your bag is empty',
            message: 'Add a pick before checkout.');
        context.go('/cart');
      } else if (_user != null && savedAddress == null && !_promptShown) {
        _promptShown = true;
        _showAddressSheet();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [name, phone, line, city, postal]) {
      controller.dispose();
    }
    super.dispose();
  }

  int get subtotal => snapshot.fold(
      0, (total, item) => total + item.unitPriceMinor * item.quantity);

  int get shipping => subtotal >= 250000 ? 0 : 4900;

  bool _validAddress() {
    if ([name, phone, line, city, postal]
        .any((field) => field.text.trim().isEmpty)) {
      AppNotifier.warning('Complete your delivery details.');
      return false;
    }
    if (!RegExp(r'^\+63\d{10}$').hasMatch(phone.text.trim())) {
      AppNotifier.warning('Use a valid +63 phone number.');
      return false;
    }
    return true;
  }

  Future<void> _saveAddress() async {
    if (!_validAddress()) return;
    final address = Address(
      fullName: name.text.trim(),
      phone: phone.text.trim(),
      line: line.text.trim(),
      city: city.text.trim(),
      postalCode: postal.text.trim(),
    );
    await LocalStore.writeDefaultAddress(ownerKey, address);
    if (mounted) Navigator.pop(context);
    AppNotifier.success('Delivery details saved');
    setState(() {});
  }

  Future<void> _showAddressSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSheet(
        name: name,
        phone: phone,
        line: line,
        city: city,
        postal: postal,
        onSave: _saveAddress,
      ),
    );
  }

  Future<void> _choosePayment() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in [
              'Cash on Delivery',
              'E-Wallet',
              'Credit / Debit Card',
            ])
              RadioListTile<String>(
                value: option,
                groupValue: payment,
                title: Text(option),
                onChanged: (value) => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => payment = result);
    await LocalStore.writePaymentMethod(ownerKey, result);
  }

  Future<void> _placeOrder() async {
    if (!_validAddress() || isPlacing) return;
    setState(() => isPlacing = true);
    try {
      final order = await ref.read(ordersProvider.notifier).placeOrder(
            cart: snapshot,
            address: Address(
              fullName: name.text.trim(),
              phone: phone.text.trim(),
              line: line.text.trim(),
              city: city.text.trim(),
              postalCode: postal.text.trim(),
            ),
            paymentMethod: payment,
            shippingMinor: shipping,
          );
      if (!mounted) return;
      AppNotifier.success('Order placed!',
          message: "We're packing your goodies.");
      context.go('/order-success/${order.number}');
    } catch (error, stackTrace) {
      debugPrint('Local order placement failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        AppNotifier.error(
          'We could not save your order',
          message: 'Your bag is still safe. Please try again.',
          actionLabel: 'Retry',
          onAction: _placeOrder,
        );
      }
    } finally {
      if (mounted) setState(() => isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review & place order')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: PawButton(
          label: isPlacing ? 'Saving your order...' : 'Place order',
          labelWidget: isPlacing
              ? null
              : Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Place order Â· '),
                      Money.span(
                        subtotal + shipping,
                        Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
          onPressed: isPlacing ? null : _placeOrder,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (_user == null) ...[
            Text('Your details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _field(name, 'Full name', TextInputType.name),
            _field(phone, 'Phone (+63)', TextInputType.phone),
            _field(line, 'House / street', TextInputType.streetAddress),
            _field(city, 'City / municipality', TextInputType.text),
            _field(postal, 'ZIP code', TextInputType.number),
            const SizedBox(height: 8),
          ],
          _OrderSummary(items: snapshot),
          const SizedBox(height: 16),
          _CheckoutCard(
            title: 'Deliver to',
            icon: Icons.location_on_rounded,
            value: '${name.text.isEmpty ? 'Add delivery details' : name.text}\n'
                '${phone.text}\n${line.text}, ${city.text} ${postal.text}',
            action: 'Change',
            onAction: _showAddressSheet,
          ),
          const SizedBox(height: 12),
          _CheckoutCard(
            title: 'Pay with',
            icon: Icons.payments_rounded,
            value: payment,
            action: 'Change',
            onAction: _choosePayment,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This is a gift'),
            value: gift,
            onChanged: (value) => setState(() => gift = value),
          ),
          const Divider(),
          _SummaryRow(label: 'Subtotal', amount: subtotal),
          _SummaryRow(
              label: 'Shipping',
              value: shipping == 0 ? 'FREE' : '',
              amount: shipping == 0 ? null : shipping),
          _SummaryRow(
            label: 'Total',
            amount: subtotal + shipping,
            isTotal: true,
          ),
          if (_user == null)
            PawButton(
              label: 'Create an account to save these details',
              variant: PawButtonVariant.text,
              height: 48,
              onPressed: () => context.push('/auth'),
            ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    TextInputType type,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          keyboardType: type,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _AddressSheet extends StatelessWidget {
  const _AddressSheet({
    required this.name,
    required this.phone,
    required this.line,
    required this.city,
    required this.postal,
    required this.onSave,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController line;
  final TextEditingController city;
  final TextEditingController postal;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Where should we deliver?',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              _sheetField(name, 'Full name', TextInputType.name),
              _sheetField(phone, 'Phone (+63)', TextInputType.phone),
              _sheetField(line, 'House / street', TextInputType.streetAddress),
              _sheetField(city, 'City / municipality', TextInputType.text),
              _sheetField(postal, 'ZIP code', TextInputType.number),
              const SizedBox(height: 8),
              PawButton(label: 'Save delivery details', onPressed: onSave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController controller,
    String label,
    TextInputType type,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your goodies',
                  style: Theme.of(context).textTheme.titleLarge),
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text('Qty ${item.quantity}'),
                  trailing: PriceText(
                    amount: item.unitPriceMinor * item.quantity,
                  ),
                ),
            ],
          ),
        ),
      );
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.title,
    required this.icon,
    this.value = '',
    required this.action,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final String value;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.blue),
          title: Text(title),
          subtitle: Text(value),
          trailing: PawButton(
            label: action,
            variant: PawButtonVariant.text,
            height: 44,
            onPressed: onAction,
          ),
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    this.value = '',
    this.amount,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final int? amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: isTotal ? Theme.of(context).textTheme.titleLarge : null),
            amount == null
                ? Text(value,
                    style:
                        isTotal ? Theme.of(context).textTheme.titleLarge : null)
                : PriceText(
                    amount: amount,
                    style:
                        isTotal ? Theme.of(context).textTheme.titleLarge : null,
                  ),
          ],
        ),
      );
}

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({required this.number, super.key});

  final String number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(ordersProvider).firstWhere(
          (item) => item.number == number,
        );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => context.go('/home'),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.softGreen,
                    child: Icon(Icons.check_rounded,
                        size: 48, color: AppColors.blue),
                  ),
                  const SizedBox(height: 20),
                  Text('Order placed!',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('Your order number is ${order.number}.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  PawButton(
                    label: 'Print / save receipt',
                    isOutlined: true,
                    onPressed: () =>
                        context.push('/receipt-preview/${order.number}'),
                  ),
                  const SizedBox(height: 12),
                  PawButton(
                    label: 'Continue shopping',
                    onPressed: () => context.go('/shop'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No orders yet',
                message: 'Your next joyful delivery will appear here.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: orders
                  .map((order) => Card(
                        child: ListTile(
                          title: Text(order.number),
                          subtitle: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                    text: '${order.items.length} items Â· '),
                                Money.span(order.totalMinor,
                                    Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/orders/${order.number}'),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.number, super.key});

  final String number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(ordersProvider).firstWhere(
          (item) => item.number == number,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.number,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              PawIconButton(
                tooltip: 'Copy order number',
                onPressed: () => AppNotifier.success('Order number copied'),
                icon: Icons.copy_rounded,
              ),
            ],
          ),
          Text('Placed ${order.createdAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          for (final status in OrderStatus.values
              .where((status) => status != OrderStatus.cancelled))
            ListTile(
              leading: Icon(
                status.index <= order.status.index
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: status.index <= order.status.index
                    ? AppColors.blue
                    : AppColors.line,
              ),
              title: Text(status.name.replaceAllMapped(
                  RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')),
            ),
          const Divider(),
          Text('Items', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final item in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text(
                '${item.color ?? ''}${item.size == null ? '' : ' Â· ${item.size}'} Â· Qty ${item.quantity}',
              ),
              trailing: PriceText(
                amount: item.unitPriceMinor * item.quantity,
              ),
            ),
          const Divider(),
          Text('Deliver to ${order.address.label}'),
          Text('Payment: ${order.paymentMethod}'),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Subtotal',
            amount: order.subtotalMinor,
          ),
          _SummaryRow(
            label: 'Shipping',
            amount: order.shippingMinor,
          ),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Total: '),
                Money.span(
                    order.totalMinor, Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PawButton(
            label: 'Save / print receipt',
            onPressed: () => context.push('/receipt-preview/${order.number}'),
          ),
          const SizedBox(height: 10),
          PawButton(
            label: 'Need help?',
            isOutlined: true,
            onPressed: () => context.push('/help'),
          ),
          const SizedBox(height: 10),
          PawButton(
            label: 'Reorder',
            isOutlined: true,
            onPressed: () => AppNotifier.info('Reorder',
                message: 'Your order items are ready to add again.'),
          ),
        ],
      ),
    );
  }
}
