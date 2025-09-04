import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> signUpUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final res = await client.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user == null) {
      throw Exception('Signup failed: no user returned.');
    }

    final insertRes = await client.from('profiles').insert({
      'user_id': user.id,
      'email': email,
      'full_name': fullName,
      'role': role,
    }).select();

    // optional: check for errors
    if (insertRes == null) {
      // In some SDK versions insert().select() returns null on failure — handle gracefully
      throw Exception('Failed to insert profile row.');
    }
  }

  // Login helper: returns role string
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

    final profile =
    await client.from('profiles').select('role').eq('user_id', user.id).maybeSingle();

    if (profile == null || profile['role'] == null) {
      throw Exception('Profile not found for user.');
    }

    return profile['role'] as String;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static Future<String> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) throw Exception('No current user.');
    final profile =
    await client.from('profiles').select('role').eq('user_id', user.id).maybeSingle();
    if (profile == null || profile['role'] == null) throw Exception('Role not found.');
    return profile['role'] as String;
  }
}
