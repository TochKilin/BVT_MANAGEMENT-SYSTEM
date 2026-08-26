import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home/Home_screen.dart';
import 'screens/auth/login.dart';
import 'services/auth_api.dart';

void main() {
  runApp(const ChartMobileApp());
}

class ChartMobileApp extends StatelessWidget {
  const ChartMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chart — Vet & Pharmacy',
      theme: ThemeData(
        scaffoldBackgroundColor: ChartColors.bg,
        fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
        useMaterial3: true,
      ),
      // ចាប់ផ្តើមកម្មវិធីតាមរយៈ AuthGate — ពិនិត្យថាតើមាន session ចាស់ឬអត់
      home: const AuthGate(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

/// ពិនិត្យស្ថានភាព login ពេល app ចាប់ផ្តើម
/// - បើមាន token ស្រាប់ (login រួច) → បង្ហាញ HomeScreen ដោយផ្ទាល់
/// - បើមិនទាន់ login → បង្ហាញ LoginScreen (ដែលអាចចុចទៅ RegisterScreen)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthApi.isLoggedIn(),
      builder: (context, snapshot) {
        // កំពុងពិនិត្យ SharedPreferences
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: ChartColors.bg,
            body: Center(child: CircularProgressIndicator(color: ChartColors.teal)),
          );
        }

        final loggedIn = snapshot.data ?? false;
        return loggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}