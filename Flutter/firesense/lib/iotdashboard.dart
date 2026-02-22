import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/iot_service.dart';
import 'sensor_detail_page.dart';

class IoTDashboardPage extends StatelessWidget {
  const IoTDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final IoTService service = IoTService();

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final data = service.latest;

        if (data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final formattedTime = DateFormat(
          "dd MMM yyyy • hh:mm:ss a",
        ).format(data.time);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),

          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            title: const Text(
              "IoT Dashboard",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 82, 0, 75),
          ),

          // ✅ SCROLLABLE BODY
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🕒 LAST UPDATED
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Last Updated: $formattedTime",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🔲 SENSOR GRID
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _sensorTile(
                      title: "Temperature",
                      value: "${data.temperature.toStringAsFixed(1)} °C",
                      icon: Icons.thermostat,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SensorDetailPage(
                              type: SensorType.temperature,
                              title: "Temperature",
                              unit: "°C",
                              color: Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
                    _sensorTile(
                      title: "Gas",
                      value: "${data.gas} ppm",
                      icon: Icons.cloud,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SensorDetailPage(
                              type: SensorType.gas,
                              title: "Gas",
                              unit: "ppm",
                              color: Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
                    _sensorTile(
                      title: "Smoke",
                      value: "${data.smoke} ppm",
                      icon: Icons.smoke_free,
                      color: Colors.grey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SensorDetailPage(
                              type: SensorType.smoke,
                              title: "Smoke",
                              unit: "ppm",
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                    _flameTile(
                      detected: data.flame,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SensorDetailPage(
                              type: SensorType.flame,
                              title: "Flame Sensor",
                              unit: "",
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // 🟢🔴 STATUS BAR
          bottomNavigationBar: Container(
            height: 65,
            color: data.unsafe ? Colors.red : Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  data.unsafe ? Icons.warning_amber : Icons.verified,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  data.unsafe ? "UNSAFE ENVIRONMENT" : "ENVIRONMENT SAFE",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- SENSOR TILE ----------------

Widget _sensorTile({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------- FLAME TILE ----------------

Widget _flameTile({required bool detected, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: detected
              ? [Colors.red.shade700, Colors.orange.shade600]
              : [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (detected ? Colors.red : Colors.green).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: 8),
          const Text(
            "Flame Sensor",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            detected ? "FLAME DETECTED" : "NO FLAME",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
