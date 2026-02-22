import 'package:flutter/material.dart';
import "package:firesense/loginpage.dart";
import 'signuppage.dart';

class CoverPage extends StatelessWidget {
  const CoverPage({super.key});

  // final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.45;
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text("FireSense", style: TextStyle(color: Colors.white)),
        ),
        // leading: Image.asset("images/logo.png", fit: BoxFit.contain),
        backgroundColor: Color.fromARGB(255, 0, 0, 162),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Real-Time Fire Accident Detection",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 255),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Instant Alerts. Safer Lives.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 91, 72),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 231, 255, 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Detect fire incidents instantly and respond before damage spreads.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Image.asset(
              //   "images/logo3.png",
              //   width: MediaQuery.of(context).size.width * 0.45,
              //   height: 150,
              // ),
              Container(
                width: size,
                height: size,

                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 0, 0),

                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage("images/logo3.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.8,
                children: [
                  _featureCard(
                    'Real-Time Fire Accident Detection',
                    const Color.fromARGB(255, 56, 0, 135),
                  ),
                  _featureCard(
                    'IoT-Based Environmental Monitoring',
                    const Color.fromARGB(255, 84, 147, 0),
                  ),
                  _featureCard(
                    'Instant Alert & Notification System',
                    const Color.fromARGB(255, 11, 133, 121),
                  ),
                  _featureCard(
                    'Secure User Management & Intelligent Monitoring',
                    const Color.fromARGB(255, 33, 49, 230),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // button color
                  foregroundColor: Colors.white, // text & icon color
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  print("Login pressed");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: const Text("Login"),
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),

                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },

                child: const Text("Sign Up"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _featureCard(String text, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white),
      textAlign: TextAlign.center,
    ),
  );
}
