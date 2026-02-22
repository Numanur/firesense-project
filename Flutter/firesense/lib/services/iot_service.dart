import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ===================== DATA MODEL =====================

class IoTData {
  final double temperature;
  final int gas;
  final int smoke;
  final bool flame;
  final bool unsafe;
  final DateTime time;

  IoTData({
    required this.temperature,
    required this.gas,
    required this.smoke,
    required this.flame,
    required this.unsafe,
    required this.time,
  });
}

class SensorPoint {
  final double value;
  final DateTime time;

  SensorPoint(this.value, this.time);
}

// ===================== SERVICE =====================

class IoTService extends ChangeNotifier {
  // 🔁 Sensor history (last 12 points = 1 minute)
  final List<SensorPoint> temperatureHistory = [];
  final List<SensorPoint> gasHistory = [];
  final List<SensorPoint> smokeHistory = [];
  final List<SensorPoint> flameHistory = [];

  // 🔒 Singleton
  static final IoTService _instance = IoTService._internal();
  factory IoTService() => _instance;
  IoTService._internal();

  late IO.Socket _socket;
  bool _connected = false;

  IoTData? _latest;
  IoTData? get latest => _latest;

  bool get connected => _connected;

  // ===================== CONNECT =====================

  void connect() {
    if (_connected) return; // 🔒 prevent duplicate sockets

    _socket = IO.io("http://192.168.1.103:3000/iot", {
      "transports": ["websocket"],
      "autoConnect": true,
      "reconnection": true,
      "reconnectionAttempts": 999,
      "reconnectionDelay": 2000,
    });

    _socket.onConnect((_) {
      _connected = true;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      _connected = false;
      notifyListeners();
    });

    _socket.onConnectError((err) {
      debugPrint("IoT socket connect error: $err");
    });

    // ===================== DATA HANDLER =====================

    _socket.on("sensor_data", (data) {
      try {
        final time = DateTime.fromMillisecondsSinceEpoch(
          (data["timestamp"] as num).toInt(),
        );

        final double temperature =
            (data["temperature"] as num?)?.toDouble() ?? 0.0;
        final int gas = (data["gas"] as num?)?.toInt() ?? 0;
        final int smoke = (data["smoke"] as num?)?.toInt() ?? 0;
        final bool flame = data["flame"] == true;
        final bool unsafe = data["unsafe"] == true;

        // 🔁 Store history (max 12)
        _addPoint(temperatureHistory, temperature, time);
        _addPoint(gasHistory, gas.toDouble(), time);
        _addPoint(smokeHistory, smoke.toDouble(), time);
        _addPoint(flameHistory, flame ? 1.0 : 0.0, time);

        // 🔄 Latest snapshot
        _latest = IoTData(
          temperature: temperature,
          gas: gas,
          smoke: smoke,
          flame: flame,
          unsafe: unsafe,
          time: time,
        );

        notifyListeners();
      } catch (e) {
        debugPrint("Sensor data parse error: $e");
      }
    });
  }

  // ===================== HELPERS =====================

  void _addPoint(List<SensorPoint> list, double value, DateTime time) {
    list.add(SensorPoint(value, time));
    if (list.length > 12) {
      list.removeAt(0);
    }
  }

  // ===================== DISCONNECT =====================

  void disconnect() {
    if (_connected) {
      _socket.off("sensor_data");
      _socket.disconnect();
      _connected = false;
      notifyListeners();
    }
  }
}
