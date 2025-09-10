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

    final response = await client.from('profiles').insert({
      'id': authRes.user!.id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'roll_no': role == 'student' ? rollNo : null,
    }).select(); // Returns the inserted row

    if (response == null || (response is List && response.isEmpty)) {
      throw Exception("Profile insert failed");
    }

    return authRes.user;
  }

  // ---------------- SIGN IN ----------------
  static Future<User?> signInUser(String email, String password) async {
    final res = await client.auth.signInWithPassword(email: email, password: password);
    return res.user;
  }

  // ---------------- GET PROFILE ----------------
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final profile = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return profile;
  }

  // ---------------- SAVE CERTIFICATE & RETURN ROW ----------------
  static Future<Map<String, dynamic>> saveCertificateAndReturnRow({
    required String cid,
    required String hash,
    required String fileName,
    required String studentRollNo,
  }) async {
    final student = await client
        .from('profiles')
        .select('id')
        .eq('roll_no', studentRollNo)
        .eq('role', 'student')
        .maybeSingle();

    if (student == null) throw Exception("No student found with roll number $studentRollNo");

    final response = await client.from('certificates').insert({
      'student_id': student['id'],
      'file_name': fileName,
      'cid': cid,
      'hash': hash,
    }).select().maybeSingle();

    if (response == null) {
      throw Exception("Failed to insert certificate row.");
    }

    return Map<String, dynamic>.from(response);
  }

  // ---------------- ATTACH ON-CHAIN INFO ----------------
  static Future<void> attachOnChainInfo({
    required String cid,
    required String txSignature,
    required int txSlot,
    required int feeLamports,
    required String network, // 'devnet' | 'mainnet'
  }) async {
    final cert = await client
        .from('certificates')
        .select('id')
        .eq('cid', cid)
        .maybeSingle();

    if (cert == null) throw Exception('Certificate not found for CID $cid');

    await client.from('certificates').update({
      'tx_signature': txSignature,
      'tx_slot': txSlot,
      'fee_lamports': feeLamports,
      'network': network,
      'explorer_url': 'https://explorer.solana.com/tx/$txSignature?cluster=$network',
    }).eq('id', cert['id']);
  }

  // ---------------- FETCH CERTIFICATES ----------------
  static Future<List<Map<String, dynamic>>> fetchAllCertificates() async {
    final data = await client
        .from('certificates')
        .select('file_name, cid, hash, created_at, student:profiles(full_name, roll_no)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }


  // ---------------- SIGN OUT ----------------
  static Future<void> signOut() async {
    await client.auth.signOut();
  }


  // Fetch unique students who have certificates
  static Future<List<Map<String, dynamic>>> fetchStudentsWithCertificates() async {
    final data = await client
        .from('certificates')
        .select('student:profiles(roll_no, full_name)')
        .order('created_at', ascending: false);

    // Deduplicate by roll_no
    final unique = <String, Map<String, dynamic>>{};
    for (var cert in data) {
      final student = cert['student'];
      if (student != null && !unique.containsKey(student['roll_no'])) {
        unique[student['roll_no']] = student;
      }
    }
    return unique.values.toList();
  }


  static Future<List<Map<String, dynamic>>> fetchCertificatesByRollNo(String rollNo) async {
    // 1. Find student id from rollNo
    final student = await client
        .from('profiles')
        .select('id, full_name, roll_no')
        .eq('roll_no', rollNo)
        .eq('role', 'student')
        .maybeSingle();

    if (student == null) return [];

    // 2. Now fetch only that student’s certificates
    final data = await client
        .from('certificates')
        .select('file_name, cid, hash, created_at, tx_signature, student:profiles(full_name, roll_no)')
        .eq('student_id', student['id']) // ✅ filter by FK
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }


  // ---------------- FETCH CERTIFICATES FOR A SPECIFIC STUDENT ----------------
  static Future<List<Map<String, dynamic>>> fetchCertificatesByRoll(String rollNo) async {
    // 1. Find student ID
    final student = await client
        .from('profiles')
        .select('id')
        .eq('roll_no', rollNo)
        .maybeSingle();

    if (student == null) return [];

    // 2. Fetch certs only for that student
    final data = await client
        .from('certificates')
        .select('file_name, cid, hash, created_at, tx_signature, student:profiles(full_name, roll_no)')
        .eq('student_id', student['id']) // ✅ filter by student_id (FK)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

}


