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

  // ---------------- SAVE CERTIFICATE ----------------
  static Future<void> saveCertificate({
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

    await client.from('certificates').insert({
      'student_id': student['id'],
      'file_name': fileName,
      'cid': cid,
      'hash': hash,
    });
  }

  // ---------------- FETCH CERTIFICATES ----------------
  static Future<List<Map<String, dynamic>>> fetchAllCertificates() async {
    final data = await client
        .from('certificates')
        .select('file_name, cid, hash, created_at, student_id, profiles(full_name, roll_no)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------- SIGN OUT ----------------
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
