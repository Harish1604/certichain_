// lib/ui/pages/student_home.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/supabase_service.dart';
import 'package:certichain/ui/auth/login_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  late Future<List<Map<String, dynamic>>> _certsFuture;
  String? _rollNo;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _certsFuture = _loadCertificates();
  }

  Future<List<Map<String, dynamic>>> _loadCertificates() async {
    final profile = await SupabaseService.getProfile();
    final roll = profile?['roll_no'] ??
        profile?['student_roll_no'] ??
        profile?['roll'] ??
        profile?['rollno'];

    _studentName = profile?['full_name'] ?? profile?['name'] ?? 'Student';
    _rollNo = roll?.toString();
    if (_rollNo == null || _rollNo!.trim().isEmpty) {
      return [];
    }

    final certs = await SupabaseService.fetchCertificatesByRoll(_rollNo!);
    return certs;
  }

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
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      const monthNames = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${monthNames[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.toString().split('T').first;
    }
  }

  Widget _buildCertTileFromRow(Map<String, dynamic> cert) {
    final title = cert['title'] ?? cert['file_name'] ?? cert['cid'] ?? 'Certificate';
    final status = cert['status'] ??
        ((cert['tx_signature'] != null && cert['tx_signature'].toString().isNotEmpty)
            ? 'Verified'
            : 'Pending');
    final date =
    _formatDate(cert['created_at'] ?? cert['uploaded_at'] ?? cert['createdAt']);

    final cid = cert['cid'] ?? cert['ipfs_cid'];
    Color statusColor = status == 'Verified' ? Colors.green : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const Icon(Icons.school, color: Colors.purpleAccent),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$status • $date", style: TextStyle(color: statusColor, fontSize: 12)),
            if (cid != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  final url = "https://gateway.pinata.cloud/ipfs/$cid";
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                child: const Text(
                  "View on IPFS",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ]
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _certsFuture = _loadCertificates();
    });
    await _certsFuture;
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _certsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load certificates:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }

          final certs = snap.data ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile block
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
                        children: [
                          const Text("Hello,", style: TextStyle(color: Colors.white70)),
                          Text(_studentName ?? 'Student',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text("Roll: ${_rollNo ?? 'Not set'}",
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
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

                if (_rollNo == null || _rollNo!.trim().isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "No roll number found in your profile — certificates can only be mapped by roll number. Please update your profile (roll_no) so issuer uploads show up here.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else if (certs.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.hourglass_empty, size: 32, color: Colors.white54),
                        SizedBox(height: 12),
                        Text("No certificates yet.",
                            style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 8),
                        Text(
                          "Check back later — the issuer might not have uploaded anything for your roll yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        )
                      ],
                    ),
                  )
                else
                  ...certs.map((c) => _buildCertTileFromRow(c)).toList(),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
