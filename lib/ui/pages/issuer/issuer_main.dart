import 'package:flutter/material.dart';
import 'upload_page.dart';
import 'certificates_page.dart';
import 'profile_page.dart';

class IssuerMainPage extends StatefulWidget {
  const IssuerMainPage({super.key});

  @override
  State<IssuerMainPage> createState() => _IssuerMainPageState();
}

class _IssuerMainPageState extends State<IssuerMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    UploadPage(),
    CertificatesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1C1F2E),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white70,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: "Upload",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: "Certificates",
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
