import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash/splash_screen.dart';
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
       scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
        useMaterial3: true,
      ),
      // Get start AuthGate 
      home: const SplashScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

/// Check when login
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthApi.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor:  Color(0xFF1F2A2E),
            body: Center(
            child: CircularProgressIndicator(
              color:  Color(0xFF1F2A2E),
            ),
          ),

          );
        }

        final loggedIn = snapshot.data ?? false;
        return loggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
