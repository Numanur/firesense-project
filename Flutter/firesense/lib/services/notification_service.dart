import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class IoTNotification {
  final String message;
  final DateTime time;
  final bool unsafe;

  IoTNotification({
    required this.message,
    required this.time,
    required this.unsafe,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal() {
    _connectSocket();
  }

  late IO.Socket _socket;

  final List<IoTNotification> _notifications = [];

  List<IoTNotification> get notifications => List.unmodifiable(_notifications);

  void _connectSocket() {
    _socket = IO.io("http://192.168.1.103:3000/iot", {
      "transports": ["websocket"],
      "autoConnect": true,
      "reconnection": true,
    });

    _socket.on("sensor_data", (data) {
      final bool unsafe = data["unsafe"] ?? false;

      if (!unsafe) return; // ✅ only notify on danger

      final String message = _buildMessage(data);

      _notifications.insert(
        0,
        IoTNotification(
          message: message,
          time: DateTime.fromMillisecondsSinceEpoch(data["timestamp"]),
          unsafe: true,
        ),
      );

      // 🔒 Keep only last 10 notifications
      if (_notifications.length > 10) {
        _notifications.removeRange(10, _notifications.length);
      }

      notifyListeners();
    });
  }

  String _buildMessage(Map data) {
    final List<String> highLevelSensors = [];
    final List<String> alerts = [];

    if ((data["gas"] ?? 0) > 300) {
      highLevelSensors.add("gas");
    }

    if ((data["smoke"] ?? 0) > 150) {
      highLevelSensors.add("smoke");
    }

    if ((data["temperature"] ?? 0) > 60) {
      highLevelSensors.add("temperature");
    }

    if (highLevelSensors.isNotEmpty) {
      alerts.add("${highLevelSensors.join(", ")} level high");
    }

    if (data["flame"] == true) {
      alerts.add("flame detected");
    }

    // Fallback (should not normally happen)
    if (alerts.isEmpty) {
      return "Unsafe environment detected";
    }

    return alerts.join(", ");
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
