// lib/ui/pages/student_home.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:certichain/ui/auth/login_page.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF1C1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await SupabaseService.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("CertiChain", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () => _showLogoutSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF7B61FF),
                    child: Text("ST", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Hello,", style: TextStyle(color: Colors.white70)),
                      Text("Student",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text("Wallet: 0x1234...ABCD",
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("My Certificates",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),

            _buildCertTile("Blockchain Fundamentals", "Verified", "02 Sep 2025"),
            _buildCertTile("AI Workshop", "Pending", "01 Sep 2025"),
          ],
        ),
      ),
    );
  }

  static Widget _buildCertTile(String title, String status, String date) {
    Color statusColor =
    status == "Verified" ? Colors.green : Colors.orangeAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.school, color: Colors.purpleAccent),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("$status • $date",
            style: TextStyle(color: statusColor, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.white70),
      ),
    );
  }
}
