import 'package:flutter/material.dart';
import 'package:certichain/services/supabase_service.dart';
import 'package:certichain/widgets/certificate_tile.dart';

class StudentCertificatesPage extends StatefulWidget {
  final String rollNo;

  const StudentCertificatesPage({super.key, required this.rollNo});

  @override
  State<StudentCertificatesPage> createState() =>
      _StudentCertificatesPageState();
}

class _StudentCertificatesPageState extends State<StudentCertificatesPage> {
  List<Map<String, dynamic>> _certificates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      final certs =
      await SupabaseService.fetchCertificatesByRollNo(widget.rollNo);
      setState(() {
        _certificates = certs;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching certificates: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // makes back arrow white
        ),
        title: Text(
          "${widget.rollNo}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
          ? const Center(
        child: Text(
          "No certificates found for this student.",
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _certificates.length,
        itemBuilder: (ctx, i) {
          final cert = _certificates[i];
          final student = cert['student'] ?? {};
          return CertificateTile(
            fileName: cert['file_name'] ?? "Unknown",
            studentName: student['full_name'] ?? "Unknown Student",
            rollNo: student['roll_no'] ?? "N/A",
          );
        },
      ),
    );
  }
}
