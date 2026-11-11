import 'package:flutter/material.dart';

import '../../../app/config.dart';
import '../../../core/colors.dart';
import '../../../core/widgets/paw_widgets.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _search = TextEditingController();
  int? _open;

  static final _faqs = [
    ('Orders', 'How do I place an order?', 'Add a pick to your bag, review checkout details, then tap Place order.'),
    ('Orders', 'What is the per-item limit?', 'You can add up to 10 units of one item, or less when stock is limited.'),
    ('Delivery', 'How much is delivery?', 'Delivery is calculated at checkout. Free shipping applies over the threshold.'),
    ('Payments', 'Which payment methods are accepted?', 'Cash on Delivery, e-wallets, and cards are supported where available.'),
    ('Returns', 'Can I return an item?', 'Contact us within 30 days for an easy return. Damaged or incorrect items are prioritized.'),
    ('Sizing', 'How do I choose a garment size?', 'Measure chest, neck, and back length, then compare them with the size guide.'),
    ('Account', 'Can I order without an account?', 'Yes. Guest orders stay on this device until you sign in and move them into your account.'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();
    final visible = _faqs
        .where((faq) => faq.$1.toLowerCase().contains(query) ||
            faq.$2.toLowerCase().contains(query) ||
            faq.$3.toLowerCase().contains(query))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('How can we help?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search for help',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 20),
          if (visible.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No answers found',
              message: 'Try another search or contact us for help.',
            )
          else
            ...visible.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              final open = _open == index;
              return Card(
                child: ExpansionTile(
                  initiallyExpanded: open,
                  onExpansionChanged: (value) =>
                      setState(() => _open = value ? index : null),
                  title: Text(faq.$2),
                  subtitle: Text(faq.$1),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(faq.$3),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
          Card(
            color: AppColors.sky,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Still need help?',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text('Email us and our pack will get back to you during store hours.'),
                  const SizedBox(height: 12),
                  SelectableText(AppConfig.supportEmail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
