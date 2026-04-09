import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gappsdd/app/app.dart';

void main() {
  testWidgets('navigates from login to visits', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GappsddApp()));

    expect(find.text('GAPP'), findsOneWidget);
    expect(find.text('Sign In Client'), findsOneWidget);
    expect(find.text('Sign In Gardener'), findsOneWidget);

    await tester.tap(find.text('Sign In Client'));
    await tester.pumpAndSettle();

    expect(find.text('Visits'), findsWidgets);
  });

  testWidgets('navigates from login to gardener visits',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GappsddApp()));

    await tester.tap(find.text('Sign In Gardener'));
    await tester.pumpAndSettle();

    expect(find.text('Visits'), findsWidgets);
  });
}
