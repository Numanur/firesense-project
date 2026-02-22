import 'package:firesense/signuppage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum LoginMode { email, username }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginMode _loginMode = LoginMode.email;

  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true; // 👁 password toggle
  String? _error;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // 🔐 LOGIN LOGIC
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final password = _passwordCtrl.text.trim();
      if (password.isEmpty) throw Exception("Password is required");

      if (_loginMode == LoginMode.email) {
        final email = _emailCtrl.text.trim();
        if (email.isEmpty) throw Exception("Email is required");

        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final username = _usernameCtrl.text.trim().toLowerCase();
        if (username.isEmpty) throw Exception("Username is required");

        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(username)
            .get();

        if (!usernameDoc.exists) {
          throw Exception("Username not found");
        }

        final uid = usernameDoc['uid'];

        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          throw Exception("User record not found");
        }

        final email = userDoc['email'];

        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🔁 FORGOT PASSWORD (FIREBASE WAY)
  void _showForgotPasswordDialog() {
    final TextEditingController emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your registered email. A reset link will be sent.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailCtrl.text.trim(),
                );

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Password reset email sent. Check your inbox.",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.35;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        centerTitle: true,
        title: const Text("Login", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 82, 0, 75),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🔵 LOGO
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage("images/logo3.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Email"),
                  selected: _loginMode == LoginMode.email,
                  onSelected: (_) {
                    setState(() {
                      _loginMode = LoginMode.email;
                      _usernameCtrl.clear();
                    });
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Username"),
                  selected: _loginMode == LoginMode.username,
                  onSelected: (_) {
                    setState(() {
                      _loginMode = LoginMode.username;
                      _emailCtrl.clear();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_loginMode == LoginMode.email)
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

            if (_loginMode == LoginMode.username)
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            // 🔁 FORGOT PASSWORD
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text("Forgot password?"),
              ),
            ),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 6, 181),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text("Login"),
            ),

            const SizedBox(height: 16),

            // 🔁 SIGN UP LINK
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 160, 13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
