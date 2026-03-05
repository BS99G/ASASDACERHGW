import 'package:bus_tracker_utc/screens/user_screens.dart';
import 'package:bus_tracker_utc/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/admin_screen.dart';

void main() {
  runApp(const BusTrackerApp());
}

class BusTrackerApp extends StatelessWidget {
  const BusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<ApiService>(create: (_) => ApiService())],
      child: MaterialApp(
        title: 'Bus Tracker UTC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF16a34a),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),
          cardTheme: CardThemeData(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const UserScreen(),
          '/admin': (context) => const AdminScreen(),
        },
      ),
    );
  }
}
