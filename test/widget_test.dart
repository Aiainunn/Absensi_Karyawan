import 'package:flutter_test/flutter_test.dart';
import 'package:absensi/app.dart';
import 'package:provider/provider.dart';
import 'package:absensi/providers/auth_provider.dart';
import 'package:absensi/providers/attendance_provider.dart';
import 'package:absensi/providers/admin_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: const AbsensiApp(),
      ),
    );

    // Verify app builds without crashing
    expect(find.byType(AbsensiApp), findsOneWidget);
  });
}
