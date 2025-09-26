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

  String _companyName = "";
  Map<String, dynamic>? _profile;

  int verifiedCount = 0;
  int flaggedCount = 0;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    final profile = await SupabaseService.getProfile();
    _profile = profile;
    _companyName = profile?['full_name'] ?? "";

    final students = await SupabaseService.fetchStudentsByCompany(_companyName);

    int verified = 0;
    int flagged = 0;
    int total = 0;
    List<Map<String, dynamic>> studentsWithCerts = [];

    for (var student in students) {
      final rollNo = student['roll_no'];
      if (rollNo == null) continue;

      final certs = await SupabaseService.fetchCertificatesByRoll(rollNo);
      if (certs.isNotEmpty) {
        verified +=
            certs.where((c) => (c['status'] ?? 'active') != 'flagged').length;
        flagged +=
            certs.where((c) => (c['status'] ?? 'active') == 'flagged').length;
        total += certs.length;

        studentsWithCerts.add({...student, 'certificates': certs});
      }
    }

    setState(() {
      _students = studentsWithCerts;
      _filteredStudents = List.from(_students);
      verifiedCount = verified;
      flaggedCount = flagged;
      totalCount = total;
      _loading = false;
    });
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStudents = List.from(_students));
      return;
    }
    setState(() {
      _filteredStudents =
          _students
              .where(
                (s) =>
                    (s['full_name'] ?? '').toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    (s['roll_no'] ?? '').toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
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
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Company",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _companyName.isNotEmpty ? _companyName : "-",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Verifier Dashboard",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildCompanyCard(),
                    Row(
                      children: [
                        _statCard(
                          "Verified",
                          verifiedCount,
                          Colors.green,
                          Icons.verified,
                        ),
                        _statCard(
                          "Flagged",
                          flaggedCount,
                          Colors.redAccent,
                          Icons.flag,
                        ),
                        _statCard(
                          "Total",
                          totalCount,
                          Colors.blue,
                          Icons.file_copy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: _filterStudents,
                      decoration: InputDecoration(
                        hintText: "Search by Name or Roll No",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1C1F2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          _filteredStudents.isEmpty
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
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blueAccent,
                                        child: Text(
                                          student['full_name'] != null &&
                                                  student['full_name']
                                                      .isNotEmpty
                                              ? student['full_name'][0]
                                                  .toUpperCase()
                                              : "?",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        student['full_name'] ?? "—",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        student['roll_no'] ?? "—",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CertificatePage(
                                                  student: student,
                                                ),
                                          ),
                                        );
                                        // If certificates changed, reload counts
                                        if (result == true) {
                                          _loadDashboard();
                                        }
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
