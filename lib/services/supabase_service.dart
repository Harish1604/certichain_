import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ---------------- SIGN UP ----------------
  static Future<void> signUpUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? rollNo,
    String? batch,
    String? course,
    String? degree,
  }) async {
    // 1️⃣ Create user in Auth (trigger handles profile insert)
    final res = await client.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user == null) throw Exception('Signup failed: no user returned.');

    // 2️⃣ Update extra profile fields (full_name + role)
    await client.from('profiles').update({
      'full_name': fullName,
      'role': role,
    }).eq('user_id', user.id);

    // 3️⃣ If student, add to students table
    if (role == 'student') {
      if (rollNo == null || batch == null || course == null || degree == null) {
        throw Exception('Missing student details for signup.');
      }

      await client.from('students').insert({
        'roll_no': rollNo,
        'full_name': fullName,
        'batch': batch,
        'course': course,
        'degree': degree,
        'profile_id': user.id, // ✅ direct link via user_id
      });
    }
  }

  // ---------------- LOGIN ----------------
  static Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) throw Exception('Login failed.');

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile == null || profile['role'] == null) {
      throw Exception('Profile not found.');
    }

    return profile['role'] as String;
  }

  // ---------------- SIGN OUT ----------------
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ---------------- CURRENT USER ----------------
  static User? get currentUser => client.auth.currentUser;

  static Future<String> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) throw Exception('No current user.');

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile == null || profile['role'] == null) {
      throw Exception('Role not found.');
    }

    return profile['role'] as String;
  }


// ---------------- SAVE CERTIFICATE ----------------
  static Future<void> saveCertificate({
    required String cid,
    required String hash,
    required String fileName,
    required String studentRollNo,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No logged in user.');

    await client.from('certificates').insert({
      'user_id': user.id, // uploader (university/admin)
      'student_roll_no': studentRollNo,
      'cid': cid,
      'hash': hash,
      'file_name': fileName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ---------------- FETCH CERTIFICATES FOR CURRENT STUDENT ----------------
  static Future<List<Map<String, dynamic>>> fetchMyCertificates() async {
    final user = currentUser;
    if (user == null) throw Exception('No logged in user.');

    final student = await client
        .from('students')
        .select('roll_no')
        .eq('user_id', user.id)
        .maybeSingle();

    if (student == null) throw Exception('Student record not found.');

    final rollNo = student['roll_no'];

    final res = await client
        .from('certificates')
        .select()
        .eq('student_roll_no', rollNo)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------- FETCH ALL STUDENT CERTIFICATES ----------------
  static Future<List<Map<String, dynamic>>> fetchAllCertificates() async {
    final role = await getCurrentUserRole();
    if (role != 'university' && role != 'admin') {
      throw Exception('Not authorized to view all certificates.');
    }

    final res = await client
        .from('certificates')
        .select('*, students(full_name, roll_no, course, batch, degree)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }
}
