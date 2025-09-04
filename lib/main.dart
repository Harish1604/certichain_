// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/auth/login_page.dart';
import 'ui/pages/student_home.dart';
import 'ui/pages/issuer_home.dart';
import 'ui/pages/verifier_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://aqbaljsrsuauwllldibu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxYmFsanNyc3VhdXdsbGxkaWJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5MDU3MTcsImV4cCI6MjA3MjQ4MTcxN30.Sgh8t-tLqeWuKjMPl5fjflYl2_6FRTlF2uLYHO9eQzg',
  );

  runApp(const MyApp());
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
        '/issuer': (_) => const IssuerHomePage(),
        '/verifier': (_) => const VerifierHomePage(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
          mainAxisAlignment: MainAxisAlignment.center, // centers vertically
          crossAxisAlignment: CrossAxisAlignment.center, // centers horizontally
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("Get Started"),
            ),

            const SizedBox(height: 40), // small gap before version text
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

