import 'package:flutter/material.dart';
import 'verifier_dashboard.dart';
import 'profile_page.dart';
import 'all_certificates_page.dart';

class VerifierHomePage extends StatefulWidget {
  const VerifierHomePage({super.key});

  @override
  State<VerifierHomePage> createState() => _VerifierHomeState();
}

class _VerifierHomeState extends State<VerifierHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const VerifierDashboard(),
    const AllCertificatesPage(),
    const VerifierProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1C1F2E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "All Certificates",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
