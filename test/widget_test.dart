import 'package:flutter_test/flutter_test.dart';
import 'package:taskguard_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskGuardApp());
    expect(find.byType(TaskGuardApp), findsOneWidget);
  });
}
