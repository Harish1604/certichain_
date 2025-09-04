// lib/ui/auth/login_page.dart
import 'package:flutter/material.dart';
import '/services/supabase_service.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final role = await SupabaseService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (role == 'Student') {
        Navigator.pushReplacementNamed(context, '/student');
      } else if (role == 'Issuer') {
        Navigator.pushReplacementNamed(context, '/issuer');
      } else if (role == 'Verifier') {
        Navigator.pushReplacementNamed(context, '/verifier');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E82F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circle logo style
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  padding: const EdgeInsets.all(30),
                  child: const Icon(Icons.lock_open,
                      size: 64, color: Colors.white),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Welcome Back",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Login to continue",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                const SizedBox(height: 40),
                _buildInputField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email,
                  obscure: false,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _passwordController,
                  hint: "Password",
                  icon: Icons.lock,
                  obscure: true,
                ),

                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _login,
                  child: const Text("Login"),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupPage()),
                  ),
                  child: const Text(
                    "Don’t have an account? Sign Up",
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
