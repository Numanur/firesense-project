import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'loginpage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool _checkingUsername = false;
  bool? _usernameAvailable;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_checkUsername);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // 🔍 Live username availability check
  Future<void> _checkUsername() async {
    final username = _usernameCtrl.text.trim().toLowerCase();

    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameAvailable = null;
        _checkingUsername = false;
      });
      return;
    }

    setState(() => _checkingUsername = true);

    final doc = await _firestore.collection('usernames').doc(username).get();

    if (!mounted) return;

    setState(() {
      _usernameAvailable = !doc.exists;
      _checkingUsername = false;
    });
  }

  Future<void> _signUp() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    if (_usernameAvailable != true) {
      setState(() => _error = "Username is not available");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final username = _usernameCtrl.text.trim().toLowerCase();

      final credential = await _authService.signUpWithEmailPassword(
        email: email,
        password: _passwordCtrl.text.trim(),
      );

      final uid = credential.user!.uid;

      await _firestore.collection('usernames').doc(username).set({
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Registration successful!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 82, 0, 75),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🔵 LOGO
            Center(
              child: Container(
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
            ),

            const SizedBox(height: 24),

            // 📧 EMAIL
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 👤 USERNAME
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(
                labelText: "Username",
                border: const OutlineInputBorder(),
                suffixIcon: _checkingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _usernameAvailable == null
                    ? null
                    : Icon(
                        _usernameAvailable! ? Icons.check_circle : Icons.cancel,
                        color: _usernameAvailable! ? Colors.green : Colors.red,
                      ),
              ),
            ),

            if (_usernameAvailable != null || _checkingUsername) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (_checkingUsername) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Checking username...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ] else if (_usernameAvailable == true) ...[
                    const Icon(Icons.check, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      "Username available",
                      style: TextStyle(color: Colors.green),
                    ),
                  ] else ...[
                    const Icon(Icons.close, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      "Username already taken",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 16),

            // 🔑 PASSWORD
            TextField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔑 CONFIRM PASSWORD
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // 🟣 SIGN UP BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _loading || _usernameAvailable != true
                  ? null
                  : _signUp,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Sign Up"),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE), // 🎨 custom background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(221, 71, 7, 7),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Color.fromARGB(
                          255,
                          0,
                          160,
                          13,
                        ), // 🎨 custom text color
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
