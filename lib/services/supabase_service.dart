import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ---------------- SIGN UP ----------------
  static Future<User?> signUpUser({
    required String email,
    required String password,
    required String fullName,
    required String role, // student | issuer | verifier
    String? rollNo,
  }) async {
    final authRes = await client.auth.signUp(email: email, password: password);
    if (authRes.user == null) throw Exception("User signup failed");

    final response =
        await client.from('profiles').insert({
          'id': authRes.user!.id,
          'full_name': fullName,
          'email': email,
          'role': role,
          'roll_no': role == 'student' ? rollNo : null,
        }).select();

    if (response == null || (response is List && response.isEmpty)) {
      throw Exception("Profile insert failed");
    }

    return authRes.user;
  }

  // ---------------- SIGN IN ----------------
  static Future<User?> signInUser(String email, String password) async {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user;
  }

  // ---------------- GET PROFILE ----------------
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final profile =
        await client.from('profiles').select().eq('id', user.id).maybeSingle();
    return profile;
  }

  // ---------------- SAVE CERTIFICATE & RETURN ROW ----------------
  static Future<Map<String, dynamic>> saveCertificateAndReturnRow({
    required String cid,
    required String hash,
    required String fileName,
    required String studentRollNo,
    required String certId, // NEW: required certId
  }) async {
    if (certId.trim().isEmpty) {
      throw Exception("Certificate ID is required.");
    }

    // Check duplicate certId
    final dup =
        await client
            .from('certificates')
            .select('id')
            .eq('cert_id', certId)
            .maybeSingle();

    if (dup != null) {
      throw Exception(
        "Certificate ID '$certId' is already used. Use a unique cert ID.",
      );
    }

    // Find student
    final student =
        await client
            .from('profiles')
            .select('id')
            .eq('roll_no', studentRollNo)
            .eq('role', 'student')
            .maybeSingle();

    if (student == null) {
      throw Exception("No student found with roll number $studentRollNo");
    }

    final response =
        await client
            .from('certificates')
            .insert({
              'student_id': student['id'],
              'file_name': fileName,
              'cid': cid,
              'hash': hash,
              'cert_id': certId,
            })
            .select()
            .maybeSingle();

    if (response == null) {
      throw Exception("Failed to insert certificate row.");
    }

    return Map<String, dynamic>.from(response);
  }

  // ---------------- FETCH CERTIFICATE BY CERT ID ----------------
  static Future<Map<String, dynamic>?> fetchCertificateById(
    String certId,
  ) async {
    final data =
        await client
            .from('certificates')
            .select(
              'id, cert_id, file_name, cid, hash, created_at, tx_signature, tx_slot, network, explorer_url, status, student:profiles(full_name, roll_no, email)',
            )
            .eq('cert_id', certId)
            .maybeSingle();

    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // ---------------- LOG VERIFICATION ----------------
  static Future<void> logVerification({
    required String certId,
    required String result,
    Map<String, dynamic>? meta,
  }) async {
    final user = client.auth.currentUser;
    await client.from('verifications').insert({
      'verifier_id': user?.id,
      'cert_id': certId,
      'result': result,
      'meta': meta ?? {},
    });
  }

  // ---------------- ATTACH ON-CHAIN INFO ----------------
  static Future<void> attachOnChainInfo({
    required String cid,
    required String txSignature,
    required int txSlot,
    required int feeLamports,
    required String network, // 'devnet' | 'mainnet'
  }) async {
    final cert =
        await client
            .from('certificates')
            .select('id')
            .eq('cid', cid)
            .maybeSingle();

    if (cert == null) throw Exception('Certificate not found for CID $cid');

    await client
        .from('certificates')
        .update({
          'tx_signature': txSignature,
          'tx_slot': txSlot,
          'fee_lamports': feeLamports,
          'network': network,
          'explorer_url':
              'https://explorer.solana.com/tx/$txSignature?cluster=$network',
        })
        .eq('id', cert['id']);
  }

  // ---------------- FETCH ALL CERTIFICATES ----------------
  static Future<List<Map<String, dynamic>>> fetchAllCertificates() async {
    final data = await client
        .from('certificates')
        .select(
          'file_name, cid, hash, created_at, student:profiles(full_name, roll_no)',
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------- SIGN OUT ----------------
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ---------------- FETCH STUDENTS WITH CERTIFICATES ----------------
  static Future<List<Map<String, dynamic>>>
  fetchStudentsWithCertificates() async {
    final data = await client
        .from('certificates')
        .select('student:profiles(roll_no, full_name)')
        .order('created_at', ascending: false);

    final unique = <String, Map<String, dynamic>>{};
    for (var cert in data) {
      final student = cert['student'];
      if (student != null && !unique.containsKey(student['roll_no'])) {
        unique[student['roll_no']] = student;
      }
    }
    return unique.values.toList();
  }

  // ---------------- FETCH CERTIFICATES BY ROLL NO ----------------
  static Future<List<Map<String, dynamic>>> fetchCertificatesByRollNo(
    String rollNo,
  ) async {
    final student =
        await client
            .from('profiles')
            .select('id, full_name, roll_no')
            .eq('roll_no', rollNo)
            .eq('role', 'student')
            .maybeSingle();

    if (student == null) return [];

    final data = await client
        .from('certificates')
        .select(
          'file_name, cid, hash, created_at, tx_signature, student:profiles(full_name, roll_no)',
        )
        .eq('student_id', student['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------- FETCH CERTIFICATES BY ROLL (alias) ----------------
  static Future<List<Map<String, dynamic>>> fetchCertificatesByRoll(
    String rollNo,
  ) async {
    final student =
        await client
            .from('profiles')
            .select('id')
            .eq('roll_no', rollNo)
            .maybeSingle();

    if (student == null) return [];

    final data = await client
        .from('certificates')
        .select(
          'file_name, cid, hash, created_at, tx_signature, student:profiles(full_name, roll_no)',
        )
        .eq('student_id', student['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------- FLAG CERTIFICATE ----------------
  static Future<void> flagCertificate(String certId, {String? reason}) async {
    await client
        .from('certificates')
        .update({
          'status': 'flagged',
          'flag_reason': reason ?? 'Forgery suspected',
        })
        .eq('cert_id', certId);
  }

  // SupabaseService.dart
  static Future<void> approveCertificate(String certId) async {
    final response =
        await Supabase.instance.client
            .from('certificates')
            .update({'status': 'active'})
            .eq('cert_id', certId)
            .select(); // use select() to get the updated row(s)

    if (response == null) {
      throw Exception("Failed to approve certificate");
    }
  }


  // ---------------- UPDATE STUDENT COMPANY ----------------
  static Future<void> updateStudentCompany({
    required String companyName,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception("No logged in user");

    await client
        .from('profiles')
        .update({'company_name': companyName})
        .eq('id', user.id);
  }


  // ---------------- FETCH STUDENTS BY COMPANY ----------------
  static Future<List<Map<String, dynamic>>> fetchStudentsByCompany(
      String companyName) async {
    final data = await client
        .from('profiles')
        .select('id, full_name, roll_no, email, company_name')
        .eq('role', 'student')
        .eq('company_name', companyName);

    return List<Map<String, dynamic>>.from(data);
  }


}
