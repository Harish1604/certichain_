import 'package:flutter/material.dart';
import 'package:certichain/services/supabase_service.dart';
import 'package:certichain/widgets/certificate_tile.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  List<Map<String, dynamic>> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      final certs = await SupabaseService.fetchAllCertificates();
      setState(() => _certificates = certs);
    } catch (e) {
      debugPrint("Error loading certificates: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Certificates",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _certificates.isEmpty
            ? const Center(
          child: Text(
            "No certificates uploaded yet.",
            style: TextStyle(color: Colors.white70),
          ),
        )
            : ListView.builder(
          itemCount: _certificates.length,
          itemBuilder: (ctx, i) {
            final cert = _certificates[i];
            return CertificateTile(
              fileName: cert['file_name'] ?? "Unknown",
              studentName: cert['students']?['full_name'] ?? "Unknown Student",
              rollNo: cert['students']?['roll_no'] ?? "N/A",
              date: cert['created_at'] ?? "",
            );
          },
        ),
      ),
    );
  }
}
