import 'package:flutter/material.dart';
import '../../../services/supabase_service.dart';
import 'package:flutter/services.dart';

class VerifierDashboard extends StatefulWidget {
  const VerifierDashboard({super.key});

  @override
  State<VerifierDashboard> createState() => _VerifierDashboardState();
}

class _VerifierDashboardState extends State<VerifierDashboard> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final allCerts = await SupabaseService.fetchAllCertificates();

    // Aggregate students with certificates
    Map<String, Map<String, dynamic>> studentsMap = {};
    for (var cert in allCerts) {
      final student = cert['student'];
      if (student == null) continue;
      final key = student['roll_no'] ?? student['full_name'];
      if (!studentsMap.containsKey(key)) {
        studentsMap[key] = {
          'full_name': student['full_name'],
          'roll_no': student['roll_no'],
          'certificates': []
        };
      }
      studentsMap[key]!['certificates'].add(cert);
    }

    _students = studentsMap.values.toList();
    _filteredStudents = List.from(_students);
    setState(() => _loading = false);
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStudents = List.from(_students));
      return;
    }
    setState(() {
      _filteredStudents = _students
          .where((s) =>
      (s['full_name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (s['roll_no'] ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showCertificates(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1F2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (_) {
        final certs = student['certificates'] ?? [];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${student['full_name']} (${student['roll_no']})",
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: certs.length,
                  itemBuilder: (context, index) {
                    final cert = certs[index];
                    final status = cert['status'] ?? 'active';
                    final verified = status == 'active';
                    final tx = cert['tx_signature'];
                    final cid = cert['cid'];
                    final ipfsUrl = cid != null ? 'https://ipfs.io/ipfs/$cid' : null;

                    return Card(
                      color: const Color(0xFF2A2D3E),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cert ID: ${cert['cert_id'] ?? '—'}",
                                style: const TextStyle(color: Colors.white)),
                            Text("File: ${cert['file_name'] ?? '—'}",
                                style: const TextStyle(color: Colors.white70)),
                            Text("Status: $status",
                                style: TextStyle(
                                    color: verified ? Colors.green : Colors.redAccent)),
                            if (tx != null)
                              SelectableText("On-chain Tx: $tx",
                                  style: const TextStyle(color: Colors.tealAccent)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (ipfsUrl != null)
                                  ElevatedButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: ipfsUrl));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("IPFS link copied")));
                                      },
                                      child: const Text("Copy IPFS Link")),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await SupabaseService.flagCertificate(cert['cert_id'],
                                        reason: "Verifier flagged as suspicious");
                                    setState(() => cert['status'] = 'flagged');
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent),
                                  child: const Text("Flag"),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await SupabaseService.approveCertificate(cert['cert_id']);
                                    setState(() => cert['status'] = 'active');
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text("Approve"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
        title:
        const Text("Verifier Dashboard", style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ===== SEARCH BOX =====
            TextField(
              controller: _searchController,
              onChanged: _filterStudents,
              decoration: InputDecoration(
                hintText: "Search by Name or Roll No",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1C1F2E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredStudents.isEmpty
                  ? const Center(
                child: Text(
                  "No students found",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  return ListTile(
                    tileColor: const Color(0xFF1C1F2E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    title: Text(
                      student['full_name'] ?? "—",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(student['roll_no'] ?? "—",
                        style:
                        const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 16),
                    onTap: () => _showCertificates(student),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
