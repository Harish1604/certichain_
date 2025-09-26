import 'package:flutter/material.dart';
import '../../../services/supabase_service.dart';

class VerifierProfilePage extends StatefulWidget {
  const VerifierProfilePage({super.key});

  @override
  State<VerifierProfilePage> createState() => _VerifierProfilePageState();
}

class _VerifierProfilePageState extends State<VerifierProfilePage> {
  Map<String, dynamic>? profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await SupabaseService.getProfile();
    setState(() {
      profile = data;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await SupabaseService.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent),
              )
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileCard(
                      "Full Name",
                      profile?['full_name'] ?? "-",
                    ),
                    const SizedBox(height: 15),
                    _buildProfileCard("Email", profile?['email'] ?? "-"),
                    const SizedBox(height: 15),
                    _buildProfileCard("Role", profile?['role'] ?? "-"),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
