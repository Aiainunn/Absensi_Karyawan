import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/admin_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'services/local_db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Local Standalone Mobile Database (runs on Android & iOS without any external PC server)
  await LocalDbService().init();

  // Initialize Firebase with fallback error handling
  // This allows the app to launch smoothly even if google-services.json is not yet configured
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase successfully initialized');
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
    debugPrint(
        'Aplikasi berjalan mandiri menggunakan database lokal perangkat.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(),
        ),
      ],
      child: const AbsensiApp(),
    ),
  );
}
