// certificate_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/supabase_service.dart';

class CertificatePage extends StatefulWidget {
  final Map<String, dynamic> student;

  const CertificatePage({super.key, required this.student});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final certs = student['certificates'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          "${student['full_name']} (${student['roll_no']})",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: certs.isEmpty
          ? const Center(
          child: Text("No Certificates Found",
              style: TextStyle(color: Colors.white70, fontSize: 16)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: certs.length,
        itemBuilder: (context, index) {
          final cert = certs[index];
          final status = cert['status'] ?? 'active';
          final verified = status == 'active';
          final tx = cert['tx_signature'];
          final cid = cert['cid'];
          final ipfsUrl =
          cid != null ? 'https://ipfs.io/ipfs/$cid' : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1C1F2E), Color(0xFF292C3F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        verified ? Icons.verified : Icons.flag,
                        color:
                        verified ? Colors.greenAccent : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Cert ID: ${cert['cert_id'] ?? '—'}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("File: ${cert['file_name'] ?? '—'}",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Status: $status",
                      style: TextStyle(
                          color: verified
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                  if (tx != null) ...[
                    const SizedBox(height: 4),
                    SelectableText("Tx: $tx",
                        style: const TextStyle(
                            color: Colors.tealAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 14),
                  if (ipfsUrl != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: ipfsUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text("IPFS link copied ✅")));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text("Copy IPFS Link"),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flag),
                          onPressed: () async {
                            await SupabaseService.flagCertificate(
                                cert['cert_id'],
                                reason:
                                "Verifier flagged as suspicious");
                            setState(() =>
                            cert['status'] = 'flagged');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: const Size.fromHeight(42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          label: const Text("Flag"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.verified),
                          onPressed: () async {
                            await SupabaseService.approveCertificate(
                                cert['cert_id']);
                            setState(() =>
                            cert['status'] = 'active');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size.fromHeight(42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          label: const Text("Approve"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
