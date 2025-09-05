import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:certichain/services/ipfs_service.dart';
import 'package:certichain/services/supabase_service.dart';
import 'package:certichain/ui/auth/login_page.dart';

class IssuerHomePage extends StatefulWidget {
  const IssuerHomePage({super.key});

  @override
  State<IssuerHomePage> createState() => _IssuerHomePageState();
}

class _IssuerHomePageState extends State<IssuerHomePage> {
  bool _uploading = false;
  List<Map<String, dynamic>> _certificates = [];

  final TextEditingController _rollNoController = TextEditingController();

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

  Future<void> _uploadCertificate() async {
    if (_rollNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a student roll number.")),
      );
      return;
    }

    try {
      setState(() => _uploading = true);

      // pick file
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final pickedFile = result.files.single;
      Uint8List fileBytes;

      if (pickedFile.bytes != null) {
        fileBytes = pickedFile.bytes!;
      } else if (pickedFile.path != null) {
        fileBytes = await File(pickedFile.path!).readAsBytes();
      } else {
        throw Exception("No file data found");
      }

      final fileName = pickedFile.name;

      // generate hash
      final hash = PinataService.generateHash(fileBytes);

      // upload to pinata
      final cid = await PinataService.uploadFile(fileBytes, fileName);

      // save to supabase
      await SupabaseService.saveCertificate(
        cid: cid,
        hash: hash,
        fileName: fileName,
        studentRollNo: _rollNoController.text.trim(),
      );

      await _loadCertificates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Certificate uploaded successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
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
          "CertiChain",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () => _showLogoutSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Roll number input
            TextField(
              controller: _rollNoController,
              decoration: InputDecoration(
                hintText: "Enter Student Roll Number",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1F2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Upload button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _uploadCertificate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _uploading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.upload, color: Colors.white),
                    label: Text(_uploading ? "Uploading..." : "Upload"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Certificates list
            const Text(
              "Recent Certificates",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            for (final cert in _certificates)
              _buildCertificateTile(
                cert['file_name'] ?? "Unknown",
                cert['students']?['full_name'] ?? "Unknown Student",
                cert['students']?['roll_no'] ?? "N/A",
                cert['created_at'] ?? "",
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCertificateTile(
      String fileName,
      String studentName,
      String rollNo,
      String date,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.purpleAccent),
        title: Text(
          fileName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "$studentName • Roll: $rollNo\n$date",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      ),
    );
  }
}
