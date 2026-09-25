import 'package:choreia/app/shell/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Turkish device locale shows honest profile copy',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    await tester.pumpWidget(const MaterialApp(home: ProfileView()));

    expect(find.text('Profil'), findsOneWidget);
    expect(find.textContaining('Hesap oluşturma ve üyelik erişimi bağlı değil'),
        findsOneWidget);
    expect(find.textContaining('kullanılabilir bir özellik yok'), findsOneWidget);
  });
}
