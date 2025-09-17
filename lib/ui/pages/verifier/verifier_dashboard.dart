import 'package:flutter/material.dart';
import '../../../services/supabase_service.dart';
import 'certificate_page.dart';

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

  int verifiedCount = 0;
  int flaggedCount = 0;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final allCerts = await SupabaseService.fetchAllCertificates();

    // Aggregate students
    Map<String, Map<String, dynamic>> studentsMap = {};
    int verified = 0, flagged = 0;

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

      if ((cert['status'] ?? 'active') == 'flagged') {
        flagged++;
      } else {
        verified++;
      }
    }

    _students = studentsMap.values.toList();
    _filteredStudents = List.from(_students);

    setState(() {
      verifiedCount = verified;
      flaggedCount = flagged;
      totalCount = allCerts.length;
      _loading = false;
    });
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

  Widget _statCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(count.toString(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ==== DASHBOARD STATS ====
            Row(
              children: [
                _statCard("Verified", verifiedCount, Colors.green, Icons.verified),
                _statCard("Flagged", flaggedCount, Colors.redAccent, Icons.flag),
                _statCard("Total", totalCount, Colors.blue, Icons.file_copy),
              ],
            ),
            const SizedBox(height: 16),

            // ==== SEARCH BOX ====
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

            // ==== STUDENT LIST ====
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
                  return Card(
                    color: const Color(0xFF1C1F2E),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          student['full_name'] != null &&
                              student['full_name'].isNotEmpty
                              ? student['full_name'][0].toUpperCase()
                              : "?",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        student['full_name'] ?? "—",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(student['roll_no'] ?? "—",
                          style: const TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CertificatePage(student: student),
                          ),
                        );
                      },
                    ),
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
