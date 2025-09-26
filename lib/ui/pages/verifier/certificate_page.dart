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
  bool _loadingAction = false;

  Future<void> _updateCertificateStatus(String certId, String newStatus) async {
    setState(() => _loadingAction = true);

    try {
      if (newStatus == 'flagged') {
        await SupabaseService.flagCertificate(certId, reason: 'Verifier flagged as suspicious');
      } else if (newStatus == 'active') {
        await SupabaseService.approveCertificate(certId);
      }

      // Update local UI
      final certIndex = widget.student['certificates']
          .indexWhere((c) => c['cert_id'] == certId);
      if (certIndex != -1) {
        setState(() => widget.student['certificates'][certIndex]['status'] = newStatus);
      }

      // Tell dashboard to refresh counts
      Navigator.of(context).pop(true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _loadingAction = false);
    }
  }

  Future<void> _confirmAction(String certId, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$action Certificate"),
        content: Text("Are you sure you want to $action this certificate?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("OK"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateCertificateStatus(certId, action == 'Flag' ? 'flagged' : 'active');
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final certs = student['certificates'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("${student['full_name']} (${student['roll_no']})",
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          final ipfsUrl = cid != null ? 'https://ipfs.io/ipfs/$cid' : null;

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
                        color: verified ? Colors.greenAccent : Colors.red,
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
                        Clipboard.setData(ClipboardData(text: ipfsUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("IPFS link copied ✅")));
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
                          onPressed: _loadingAction
                              ? null
                              : () =>
                              _confirmAction(cert['cert_id'], 'Flag'),
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
                          onPressed: _loadingAction
                              ? null
                              : () =>
                              _confirmAction(cert['cert_id'], 'Approve'),
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
