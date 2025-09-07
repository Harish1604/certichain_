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
  final TextEditingController _walletController = TextEditingController();

  String? _walletAddress;
  String _issuerName = "Issuer";

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

  bool _isValidEthAddress(String address) {
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }

  Future<void> _connectWalletManually() async {
    final input = _walletController.text.trim();
    if (!_isValidEthAddress(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid wallet address!")),
      );
      return;
    }

    final profile = await SupabaseService.getProfile();
    setState(() {
      _walletAddress = input; // user-entered wallet
      _issuerName = profile?['full_name'] ?? "Issuer"; // get name from Supabase
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Wallet address saved!")),
    );
  }

  Future<void> _uploadCertificate() async {
    if (_walletAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your wallet address first!")),
      );
      return;
    }

    if (_rollNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a student roll number.")),
      );
      return;
    }

    try {
      setState(() => _uploading = true);

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
      final hash = PinataService.generateHash(fileBytes);
      final cid = await PinataService.uploadFile(fileBytes, fileName);

      await SupabaseService.saveCertificate(
        cid: cid,
        hash: hash,
        fileName: fileName,
        studentRollNo: _rollNoController.text.trim(),
      );

      await _loadCertificates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Certificate uploaded ✅ (Wallet: $_walletAddress)")),
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
            // Manual Wallet Input
            if (_walletAddress == null) ...[
              TextField(
                controller: _walletController,
                decoration: InputDecoration(
                  hintText: "Enter your wallet address",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1C1F2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _connectWalletManually,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Wallet",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ] else
              Card(
                color: const Color(0xFF1C1F2E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Issuer: $_issuerName",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            "Wallet: ${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _walletAddress = null;
                            _walletController.clear();
                          });
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                      )
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

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
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "$studentName • Roll: $rollNo\n$date",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white70, size: 16),
      ),
    );
  }
}
