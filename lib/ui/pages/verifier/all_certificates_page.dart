import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/supabase_service.dart';

class AllCertificatesPage extends StatefulWidget {
  const AllCertificatesPage({super.key});

  @override
  State<AllCertificatesPage> createState() => _AllCertificatesPageState();
}

class _AllCertificatesPageState extends State<AllCertificatesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> certificates = [];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }


  Future<void> _loadCertificates() async {
    final data = await SupabaseService.fetchAllCertificates();
    setState(() {
      certificates = data;
      _loading = false;
    });
  }

  void _verifyCertificate(Map<String, dynamic> cert) async {
    // Simply mark verified in log; dashboard tracks stats
    await SupabaseService.logVerification(certId: cert['cert_id'], result: 'verified');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Certificate Verified")));
    _loadCertificates();
  }

  void _flagCertificate(Map<String, dynamic> cert) async {
    await SupabaseService.flagCertificate(cert['cert_id'], reason: "Verifier flagged");
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Certificate Flagged")));
    _loadCertificates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("All Certificates", style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: certificates.length,
        itemBuilder: (context, index) {
          final cert = certificates[index];
          final student = cert['student'] ?? {};
          final status = cert['status'] ?? 'active';

          return Card(
            color: const Color(0xFF1C1F2E),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text("${student['full_name'] ?? '—'}", style: const TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Roll No: ${student['roll_no'] ?? '—'}", style: const TextStyle(color: Colors.white70)),
                  Text("Cert ID: ${cert['cert_id'] ?? '—'}", style: const TextStyle(color: Colors.white70)),
                  Text("Status: $status", style: TextStyle(color: status == 'flagged' ? Colors.redAccent : Colors.green)),
                ],
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.verified, color: Colors.green),
                    onPressed: () => _verifyCertificate(cert),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag, color: Colors.redAccent),
                    onPressed: () => _flagCertificate(cert),
                  ),
                ],
              ),
            ),
          );
        },
      ),

    );
  }
}
