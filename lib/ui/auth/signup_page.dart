// lib/ui/auth/signup_page.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../theme/app_theme.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = "Student";
  bool _loading = false;

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.signUpUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful! Please login."),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration("Full Name"),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email"),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration("Password"),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(
                        value: 'Student', child: Text('Student')),
                    DropdownMenuItem(
                        value: 'Issuer', child: Text('Issuer')),
                    DropdownMenuItem(
                        value: 'Verifier', child: Text('Verifier')),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  decoration: _inputDecoration("Role"),
                  dropdownColor: AppTheme.primaryColor,
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _signUp,
                  child: const Text("Sign Up"),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
