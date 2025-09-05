import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _batchController = TextEditingController();
  final _courseController = TextEditingController();
  final _degreeController = TextEditingController();

  String _selectedRole = 'student';
  bool _loading = false;

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.signUpUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _selectedRole,
        rollNo: _selectedRole == 'student' ? _rollNoController.text.trim() : null,
        batch: _selectedRole == 'student' ? _batchController.text.trim() : null,
        course: _selectedRole == 'student' ? _courseController.text.trim() : null,
        degree: _selectedRole == 'student' ? _degreeController.text.trim() : null,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("Verify Your Email"),
              ],
            ),
            content: const Text(
              "We’ve sent a verification link to your email. "
                  "Please check your inbox and verify your account before logging in.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E82F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                  padding: const EdgeInsets.all(30),
                  child: const Icon(Icons.person_add, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text("Sign up to get started", style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 40),

                _buildInputField(_nameController, "Full Name", Icons.person),
                const SizedBox(height: 16),
                _buildInputField(_emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildInputField(_passwordController, "Password", Icons.lock, obscure: true),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'university', child: Text('University')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  decoration: _dropdownDecoration(),
                ),
                const SizedBox(height: 16),

                if (_selectedRole == 'student') ...[
                  _buildInputField(_rollNoController, "Roll Number", Icons.confirmation_number),
                  const SizedBox(height: 16),
                  _buildInputField(_batchController, "Batch", Icons.calendar_today),
                  const SizedBox(height: 16),
                  _buildInputField(_courseController, "Course", Icons.book),
                  const SizedBox(height: 16),
                  _buildInputField(_degreeController, "Degree", Icons.school),
                  const SizedBox(height: 16),
                ],

                _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      hintStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
    );
  }
}
