import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shravani_thermal/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Login screen is shown at launch when there is no session', (WidgetTester tester) async {
    await tester.pumpWidget(const ThermalAIBridgeApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Inspection Ai'), findsWidgets);
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('Login  →'), findsOneWidget);
  });

  testWidgets('Login screen validates empty User ID', (WidgetTester tester) async {
    await tester.pumpWidget(const ThermalAIBridgeApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Login  →'), findsOneWidget);

    await tester.tap(find.text('Login  →'));
    await tester.pump();

    expect(find.text('Please enter your User ID.'), findsOneWidget);
    expect(find.text('Login  →'), findsOneWidget);
  });
}
