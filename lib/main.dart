import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart'; // <-- make sure import path is right

import 'ui/auth/login_page.dart';
import 'ui/pages/student/student_home.dart';
import 'ui/pages/issuer/issuer_main.dart';
import 'ui/pages/verifier_home.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qxxmajyoxnuhavxgtgmw.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4eG1hanlveG51aGF2eGd0Z213Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNjg3OTYsImV4cCI6MjA3Mjc0NDc5Nn0.90s1l9PDylLpirQr-es8NFRsBlhf4Ghq1gYFTscOo2U',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CertiChain',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/student': (_) => const StudentHomePage(),
        '/issuer': (_) => const IssuerMainPage(),
        '/verifier': (_) => const VerifierHomePage(),
        '/login': (_) => const LoginPage(),
      },
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await SupabaseService.getProfile();
      final role = profile?['role'] ?? 'student';
      if (role == 'issuer') {
        Navigator.pushReplacementNamed(context, '/issuer');
      } else if (role == 'verifier') {
        Navigator.pushReplacementNamed(context, '/verifier');
      } else {
        Navigator.pushReplacementNamed(context, '/student');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E82F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo circle
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              padding: const EdgeInsets.all(30),
              child: const Icon(
                Icons.verified,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "CertiChain",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Blockchain Verified Certificates",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Get Started"),
            ),
            const SizedBox(height: 40),
            const Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

}

