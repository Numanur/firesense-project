import 'dart:convert';
import 'dart:typed_data';
import 'package:firesense/iotdashboard.dart';
import 'package:firesense/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firesense/services/notification_service.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final NotificationService _notificationService = NotificationService();

  late IO.Socket socket;

  Uint8List? currentFrame;
  int fireArea = 0;
  int smokeArea = 0;
  bool anyAlert = false;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  void connectSocket() {
    socket = IO.io("http://192.168.1.103:3000/app", {
      "transports": ["websocket"],
      "autoConnect": true,
    });

    socket.onConnect((_) {
      debugPrint("🔥 Connected to Node.js /app namespace");
    });

    socket.onDisconnect((_) {
      debugPrint("❌ Disconnected from server");
    });

    socket.on("frame", (data) {
      try {
        setState(() {
          currentFrame = base64Decode(data["frame_b64"]);
          fireArea = data["fire_area"];
          smokeArea = data["smoke_area"];
          anyAlert = data["any_alert"];
        });
      } catch (e) {
        debugPrint("Frame decode error: $e");
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) async {
    if (index == 0) {
      // 📡 IoT Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IoTDashboardPage(), // <-- create this page
        ),
      );
    } else if (index == 1) {
      // 🔐 Logout
      await FirebaseAuth.instance.signOut();
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset("images/logo.png", fit: BoxFit.contain),
        ),
        centerTitle: true,
        title: const Text(
          "FireSense Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          AnimatedBuilder(
            animation: _notificationService,
            builder: (context, _) {
              final count = _notificationService.notifications.length;

              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_sharp,
                      color: Colors.white,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],

        backgroundColor: const Color.fromARGB(255, 82, 0, 75),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              // 🔲 VIDEO / PLACEHOLDER AREA
              Expanded(
                child: Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: currentFrame == null
                        ? const Text(
                            "Connect to the server",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )
                        : Image.memory(currentFrame!, fit: BoxFit.contain),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🟢 STATUS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 18),
                    children: [
                      const TextSpan(
                        text: "Status: ",
                        style: TextStyle(color: Colors.black),
                      ),
                      TextSpan(
                        text: anyAlert ? "ALERT" : "Normal",
                        style: TextStyle(
                          color: anyAlert ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color.fromARGB(255, 82, 0, 75),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: "IoT Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }
}
