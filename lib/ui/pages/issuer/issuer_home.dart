import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:certichain/services/ipfs_service.dart';
import 'package:certichain/services/supabase_service.dart';
import 'package:certichain/ui/auth/login_page.dart';
import 'package:solana/solana.dart';
import 'package:bs58/bs58.dart'; // base58
import 'package:provider/provider.dart';
import 'package:certichain/providers/wallet_provider.dart';


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
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _mnemonicController = TextEditingController();

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

  bool _isValidSolanaAddress(String address) {
    try {
      final pubKey = Ed25519HDPublicKey.fromBase58(address);
      return pubKey.bytes.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _connectWalletManually() async {
    final input = _walletController.text.trim();
    if (!_isValidSolanaAddress(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Solana wallet address!")),
      );
      return;
    }

    final profile = await SupabaseService.getProfile();

    Provider.of<WalletProvider>(context, listen: false).setWallet(
      input,
      issuerName: profile?['full_name'] ?? "Issuer",
    );


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Wallet address saved!")),
    );
  }

  Future<void> _uploadCertificate() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    if (!walletProvider.isConnected) {
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

    if (_privateKeyController.text.trim().isEmpty &&
        _mnemonicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your private key or mnemonic!")),
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

      // Save in Supabase
      await SupabaseService.saveCertificateAndReturnRow(
        cid: cid,
        hash: hash,
        fileName: fileName,
        studentRollNo: _rollNoController.text.trim(),
      );

      // --- Solana Transaction ---
      final client = SolanaClient(
        rpcUrl: Uri.parse("https://api.devnet.solana.com"),
        websocketUrl: Uri.parse("wss://api.devnet.solana.com"),
      );

      Ed25519HDKeyPair issuerKeypair;

      if (_mnemonicController.text.trim().isNotEmpty) {
        issuerKeypair =
        await Ed25519HDKeyPair.fromMnemonic(_mnemonicController.text.trim());
      } else {
        final secretKey = base58.decode(_privateKeyController.text.trim());
        final seed = secretKey.length > 32 ? secretKey.sublist(0, 32) : secretKey;
        issuerKeypair =
        await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: seed);
      }

      final message = Message(
        instructions: [
          MemoInstruction(
            memo: "CID: $cid",
            signers: [issuerKeypair.publicKey],
          ),
        ],
      );

      final txSig = await client.rpcClient.signAndSendTransaction(
        message,
        [issuerKeypair],
      );

      final txData = await client.rpcClient.getTransaction(txSig);
      final slot = txData?.slot ?? 0;
      final fee = txData?.meta?.fee ?? 0;

      // Attach on-chain info in Supabase
      await SupabaseService.attachOnChainInfo(
        cid: cid,
        txSignature: txSig,
        txSlot: slot,
        feeLamports: fee,
        network: "devnet",
      );

      await _loadCertificates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Certificate uploaded ✅ (Tx: $txSig)")),
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
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  // Clear wallet state
                  Provider.of<WalletProvider>(context, listen: false).clearWallet();

                  // Supabase sign out
                  await SupabaseService.signOut();

                  // Go back to login
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
                  hintText: "Enter your Solana wallet address",
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
              TextField(
                controller: _privateKeyController,
                decoration: InputDecoration(
                  hintText: "Enter your private key (base58)",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1C1F2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mnemonicController,
                decoration: InputDecoration(
                  hintText: "Or enter your mnemonic",
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
                  "   Se Wallet   ",
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
                            _privateKeyController.clear();
                            _mnemonicController.clear();
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
