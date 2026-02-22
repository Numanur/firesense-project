import 'package:flutter/material.dart';
import 'package:firesense/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: service.clear),
        ],
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final notifications = service.notifications;

          if (notifications.isEmpty) {
            return const Center(child: Text("No alerts yet"));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(n.message),
                subtitle: Text(
                  DateFormat("dd MMM yyyy • hh:mm:ss a").format(n.time),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
