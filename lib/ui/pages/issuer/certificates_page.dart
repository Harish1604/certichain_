import 'package:flutter/material.dart';
import 'package:certichain/services/supabase_service.dart';
import 'student_certificates_page.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _loading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await SupabaseService.fetchStudentsWithCertificates();
      setState(() {
        _students = students;
        _filteredStudents = students; // initially full list
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching students: $e");
      setState(() => _loading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredStudents = _students.where((student) {
        final name = (student['full_name'] ?? "").toLowerCase();
        final rollNo = (student['roll_no'] ?? "").toLowerCase();
        final certId = (student['cert_id'] ?? "").toLowerCase();
        return name.contains(_searchQuery) ||
            rollNo.contains(_searchQuery) ||
            certId.contains(_searchQuery);
      }).toList();
    });
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔍 Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterStudents,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by Name, Roll No, or Cert ID...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1C1F2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📋 Student list
          Expanded(
            child: _filteredStudents.isEmpty
                ? const Center(
              child: Text(
                "No certificates found.",
                style: TextStyle(color: Colors.white70),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStudents.length,
              itemBuilder: (ctx, i) {
                final student = _filteredStudents[i];
                final rollNo = student['roll_no'] ?? "N/A";
                final name = student['full_name'] ?? "Unknown Student";

                return Card(
                  color: const Color(0xFF1C1F2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Roll No: $rollNo",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentCertificatesPage(rollNo: rollNo),
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
    );
  }
}
