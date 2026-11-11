import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/app_notifier.dart';
import '../../../core/widgets/paw_widgets.dart';
import '../../../app/theme.dart';
import '../../../data/local_store.dart';
import '../../../domain/models/order.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  Address? _address;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line = TextEditingController();
  final _city = TextEditingController();
  final _zip = TextEditingController();

  String get _scope => Firebase.apps.isNotEmpty
      ? FirebaseAuth.instance.currentUser?.uid ?? LocalStore.guestScope
      : LocalStore.guestScope;

  @override
  void initState() {
    super.initState();
    _address = LocalStore.readDefaultAddress(_scope);
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _line, _city, _zip]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _edit() async {
    final current = _address;
    _name.text = current?.fullName ?? '';
    _phone.text = current?.phone ?? '';
    _line.text = current?.line ?? '';
    _city.text = current?.city ?? '';
    _zip.text = current?.postalCode ?? '';
    final formKey = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(current == null ? 'Add address' : 'Edit address',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _field(_name, 'Full name'),
                _field(_phone, 'Phone (+63...)',
                    validator: (value) => value != null &&
                            RegExp(r'^\+63\d{10}$').hasMatch(value.trim())
                        ? null
                        : 'Use +63 followed by 10 digits'),
                _field(_line, 'House and street'),
                _field(_city, 'City / municipality'),
                _field(_zip, 'ZIP code'),
                const SizedBox(height: 8),
                PawButton(
                  label: 'Save address',
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(
                      context,
                      Address(
                        fullName: _name.text.trim(),
                        phone: _phone.text.trim(),
                        line: _line.text.trim(),
                        city: _city.text.trim(),
                        postalCode: _zip.text.trim(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == null) return;
    await LocalStore.writeDefaultAddress(_scope, saved);
    if (!mounted) return;
    setState(() => _address = saved);
    AppNotifier.success('Address saved');
  }

  Widget _field(TextEditingController controller, String label,
      {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Enter $label'
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn =
        Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Addresses')),
        body: const Center(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to manage addresses',
            message: 'Your delivery details are private to your account.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_address == null)
            EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              message: 'Add a delivery address for a faster checkout.',
              action: PawButton(label: 'Add your first address', onPressed: _edit),
            )
          else
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.palePink,
                  child: Icon(Icons.home_rounded, color: AppColors.blue),
                ),
                title: Text(_address!.fullName),
                subtitle: Text('${_address!.label}\n${_address!.phone}'),
                isThreeLine: true,
                trailing: PawIconButton(
                  tooltip: 'Edit address',
                  onPressed: _edit,
                  icon: Icons.edit_rounded,
                ),
              ),
            ),
          if (_address != null) ...[
            const SizedBox(height: 12),
            PawButton(label: 'Add another address', isOutlined: true, onPressed: _edit),
          ],
        ],
      ),
    );
  }
}
