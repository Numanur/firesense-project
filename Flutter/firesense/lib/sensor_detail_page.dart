//
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'services/iot_service.dart';

enum SensorType { temperature, gas, smoke, flame }

class SensorDetailPage extends StatelessWidget {
  final SensorType type;
  final String title;
  final String unit;
  final Color color;

  const SensorDetailPage({
    super.key,
    required this.type,
    required this.title,
    required this.unit,
    required this.color,
  });

  // 🎯 Visual max values (for graph scaling only)
  double _visualMax() {
    switch (type) {
      case SensorType.temperature:
        return 100; // °C
      case SensorType.gas:
        return 600; // ppm
      case SensorType.smoke:
        return 400; // ppm
      case SensorType.flame:
        return 1; // binary
    }
  }

  // 🎯 Clamp value for drawing (does NOT change real value)
  double _scaledValue(double value, double max) {
    return value > max ? max : value;
  }

  @override
  Widget build(BuildContext context) {
    final IoTService service = IoTService();
    final double graphHeight = MediaQuery.of(context).size.height * 0.42;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final data = service.latest;
        if (data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        late List<SensorPoint> history;
        late double currentValue;

        switch (type) {
          case SensorType.temperature:
            history = service.temperatureHistory;
            currentValue = data.temperature;
            break;
          case SensorType.gas:
            history = service.gasHistory;
            currentValue = data.gas.toDouble();
            break;
          case SensorType.smoke:
            history = service.smokeHistory;
            currentValue = data.smoke.toDouble();
            break;
          case SensorType.flame:
            history = service.flameHistory;
            currentValue = data.flame ? 1 : 0;
            break;
        }

        final double maxY = _visualMax();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              title,
              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
            backgroundColor: color,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔢 CURRENT VALUE CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Current Value",
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type == SensorType.flame
                            ? (currentValue == 1
                                  ? "FLAME DETECTED"
                                  : "NO FLAME")
                            : "${currentValue.toStringAsFixed(1)} $unit",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 📊 GRAPH HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sensor Trend (Last 1 Minute)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "X-axis: Time (5 sec interval)   •   Y-axis: $title ${unit.isNotEmpty ? "($unit)" : ""}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 📈 GRAPH (CLAMPED & SCALED)
                Container(
                  height: graphHeight,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: history.isEmpty
                      ? const Center(child: Text("No data yet"))
                      : LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY,
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: true),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: Colors.black87,
                                getTooltipItems: (spots) {
                                  return spots.map((spot) {
                                    final point = history[spot.x.toInt()];
                                    return LineTooltipItem(
                                      type == SensorType.flame
                                          ? (point.value == 1
                                                ? "FLAME DETECTED"
                                                : "NO FLAME")
                                          : "${point.value.toStringAsFixed(1)} $unit\n"
                                                "${DateFormat("hh:mm:ss").format(point.time)}",
                                      const TextStyle(color: Colors.white),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  history.length,
                                  (i) => FlSpot(
                                    i.toDouble(),
                                    _scaledValue(history[i].value, maxY),
                                  ),
                                ),
                                isCurved: type != SensorType.flame,
                                color: color,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: color.withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
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
