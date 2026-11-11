import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawpick/main.dart';

void main() {
  testWidgets('PawPick opens onboarding on first run', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PawPickApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('PawPick'), findsWidgets);
    expect(find.textContaining('Little things,'), findsOneWidget);
  });
}
