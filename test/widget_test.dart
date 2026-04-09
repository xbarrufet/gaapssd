import 'package:flutter_test/flutter_test.dart';

import 'package:gappsdd/app/app.dart';

void main() {
  testWidgets('navigates from login to visits', (WidgetTester tester) async {
    await tester.pumpWidget(const GappsddApp());

    expect(find.text('GAPP'), findsOneWidget);
    expect(find.text('Sign In Client'), findsOneWidget);
    expect(find.text('Sign In Gardener'), findsOneWidget);

    await tester.tap(find.text('Sign In Client'));
    await tester.pumpAndSettle();

    expect(find.text('Visits'), findsWidgets);
    expect(find.text('Casa Rural Puig'), findsOneWidget);
    expect(find.text('Pruning and Clearing'), findsOneWidget);
  });

  testWidgets('navigates from login to assigned gardens for gardener mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GappsddApp());

    await tester.tap(find.text('Sign In Gardener'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Harvest'), findsOneWidget);
    expect(find.text('Assigned Gardens'), findsOneWidget);
    expect(find.text('Villa Hortensia'), findsOneWidget);
  });

}
