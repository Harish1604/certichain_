import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollNoController = TextEditingController();
  String _selectedRole = 'student';
  bool _loading = false;

  void _signup() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final rollNo = _rollNoController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        (_selectedRole == 'student' && rollNo.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final user = await SupabaseService.signUpUser(
        email: email,
        password: password,
        fullName: fullName,
        role: _selectedRole,
        rollNo: _selectedRole == 'student' ? rollNo : null,
      );

      // Show verification alert
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Verify Your Email"),
          content: Text(
              "A verification link has been sent to ${user?.email}. Please check your inbox and verify your account."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            const Text("Sign Up",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _buildTextField(_fullNameController, "Full Name"),
            const SizedBox(height: 16),
            _buildTextField(_emailController, "Email"),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, "Password", obscure: true),
            const SizedBox(height: 16),
            if (_selectedRole == 'student')
              _buildTextField(_rollNoController, "Roll Number"),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: const Color(0xFF1C1F2E),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1C1F2E),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'student',
                    child:
                    Text("Student", style: TextStyle(color: Colors.white))),
                DropdownMenuItem(
                    value: 'issuer',
                    child:
                    Text("Issuer", style: TextStyle(color: Colors.white))),
                DropdownMenuItem(
                    value: 'verifier',
                    child:
                    Text("Verifier", style: TextStyle(color: Colors.white))),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedRole = value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1C1F2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
