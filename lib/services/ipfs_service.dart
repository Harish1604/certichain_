import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PinataService {
  // ⚠️ Replace with your JWT (never commit real secret in production)
  static const String pinataJwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiIxZmMyNmVhOS0zM2ViLTQ0NTEtYmY1OS0xNWNlMjI1OThlNmQiLCJlbWFpbCI6ImhhcmlzaC4xNjQwNUBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicGluX3BvbGljeSI6eyJyZWdpb25zIjpbeyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJGUkExIn0seyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJOWUMxIn1dLCJ2ZXJzaW9uIjoxfSwibWZhX2VuYWJsZWQiOmZhbHNlLCJzdGF0dXMiOiJBQ1RJVkUifSwiYXV0aGVudGljYXRpb25UeXBlIjoic2NvcGVkS2V5Iiwic2NvcGVkS2V5S2V5IjoiOWUzNWQ3ODY4ZGY3NzE4NjJiYjQiLCJzY29wZWRLZXlTZWNyZXQiOiJmZjM3YzYzYjQzNjgyYjk0ZTZkOTEzNGE0ZjJlZGFiMDM0YjBiNzEyOGJlNjQ2ZmM0ZTEyMTJlMDQ4Y2RjMGFhIiwiZXhwIjoxNzg4NTE0OTEyfQ.Hp8EFfnp9wbWssp2p2cXl8u6ZNhOqCBM8qvdF8b1qyE";
  static const String pinataUrl =
      "https://api.pinata.cloud/pinning/pinFileToIPFS";

  /// Generate SHA-256 hash of file
  static String generateHash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Upload file to Pinata → return CID
  static Future<String> uploadFile(Uint8List fileBytes, String fileName) async {
    try {
      final request = http.MultipartRequest("POST", Uri.parse(pinataUrl));
      request.headers['Authorization'] = "Bearer $pinataJwt";
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        return json['IpfsHash']; // CID from Pinata
      } else {
        throw Exception("Failed to upload: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error uploading file: $e");
    }
  }

  /// Get public gateway URL for CID
  static String getFileUrl(String cid) {
    return "https://gateway.pinata.cloud/ipfs/$cid";
  }
}
