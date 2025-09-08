import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:certichain/services/ipfs_service.dart';
import 'package:certichain/services/supabase_service.dart';
import 'package:solana/solana.dart';
import 'package:bs58/bs58.dart';


class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _uploading = false;
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _mnemonicController = TextEditingController();

  String? _walletAddress;
  String _issuerName = "Issuer";
  int? _walletBalanceLamports;
  int? _gasFeeLamports;

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
    setState(() {
      _walletAddress = input;
      _issuerName = profile?['full_name'] ?? "Issuer";
    });

    await _fetchWalletBalance();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Wallet address saved!")),
    );
  }

  Future<void> _fetchWalletBalance() async {
    if (_walletAddress == null) return;

    try {
      final client = SolanaClient(
        rpcUrl: Uri.parse("https://api.devnet.solana.com"),
        websocketUrl: Uri.parse("wss://api.devnet.solana.com"),
      );

      final balanceResult = await client.rpcClient.getBalance(_walletAddress!);
      setState(() {
        _walletBalanceLamports = balanceResult.value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch balance: $e")),
      );
    }
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

      await SupabaseService.saveCertificateAndReturnRow(
        cid: cid,
        hash: hash,
        fileName: fileName,
        studentRollNo: _rollNoController.text.trim(),
      );

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
        final seed =
        secretKey.length > 32 ? secretKey.sublist(0, 32) : secretKey;
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

      await SupabaseService.attachOnChainInfo(
        cid: cid,
        txSignature: txSig,
        txSlot: slot,
        feeLamports: fee,
        network: "devnet",
      );

      setState(() {
        _gasFeeLamports = fee;
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Upload Certificate",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_walletAddress == null) ...[
              TextField(
                controller: _walletController,
                decoration: _inputDecoration("Enter your Solana wallet address"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _privateKeyController,
                decoration: _inputDecoration("Enter your private key (base58)"),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mnemonicController,
                decoration: _inputDecoration("Or enter your mnemonic"),
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
                  "   Save Wallet   ",
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
                          if (_walletBalanceLamports != null)
                            Text(
                              "Balance: ${_walletBalanceLamports! / 1e9} SOL",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          if (_gasFeeLamports != null)
                            Text(
                              "Gas Fee: ${_gasFeeLamports! / 1e9} SOL",
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
            TextField(
              controller: _rollNoController,
              decoration: _inputDecoration("Enter Student Roll Number"),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1C1F2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}