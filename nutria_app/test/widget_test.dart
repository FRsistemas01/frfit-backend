import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nutria_app/main.dart';

void main() {
  testWidgets('La app arranca y muestra el splash inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const NutriaApp());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
