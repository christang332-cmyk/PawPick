import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'data/local_store.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalStore.init();
  runApp(const ProviderScope(child: PawPickApp()));
}

class PawPickApp extends ConsumerWidget {
  const PawPickApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PawPick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: null,
      builder: (context, child) => child ?? const SizedBox.shrink(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
