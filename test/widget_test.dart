import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // اختبار إقلاع أساسي للتأكد أن التطبيق يفتح بدون انهيار.
  testWidgets('Raqib app boots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'system',
      'language': 'ar',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(RaqibApp(prefs: prefs));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
