import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ---------------- SIGN UP ----------------
  static Future<void> signUpUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) throw Exception('Signup failed: no user returned.');

    final insertRes = await client.from('profiles').insert({
      'user_id': user.id,
      'email': email,
      'full_name': fullName,
      'role': role,
    }).select(); // 👈 ensure execution + returns rows

    if (insertRes.isEmpty) {
      throw Exception('Failed to insert profile row.');
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
    if (user == null) throw Exception('Login failed: invalid credentials.');

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile == null || profile['role'] == null) {
      throw Exception('Profile not found for user.');
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
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No logged in user.');

    final insertRes = await client.from('certificates').insert({
      'user_id': user.id,
      'cid': cid,
      'hash': hash,
      'file_name': fileName,
      'created_at': DateTime.now().toIso8601String(),
    }).select(); // 👈 execute & return inserted rows

    if (insertRes.isEmpty) {
      throw Exception('Failed to save certificate.');
    }
  }

  // ---------------- FETCH USER CERTIFICATES ----------------
  static Future<List<Map<String, dynamic>>> fetchCertificates() async {
    final user = currentUser;
    if (user == null) throw Exception('No logged in user.');

    final res = await client
        .from('certificates')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }
}
