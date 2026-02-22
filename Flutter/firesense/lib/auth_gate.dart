import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'coverpage.dart';
import 'detectionscreen.dart';
import 'services/iot_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔐 LOGGED OUT → force new widget
        if (!snapshot.hasData) {
          return const CoverPage(key: ValueKey('cover_page'));
        }

        IoTService().connect();

        // 🔓 LOGGED IN → force new widget
        return const DetectionScreen(key: ValueKey('detection_screen'));
      },
    );
  }
}
