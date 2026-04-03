import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import 'job_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => notificationProvider.clearNotifications(),
          )
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text("No new notifications"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.work, color: Colors.white),
            ),
            onTap: () {
              // 👇 Agar jobId hai toh navigate karo
              if (notifications[i].jobId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailScreen(jobId: notifications[i].jobId),
                  ),
                );
              }
            },
            title: Text(notifications[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notifications[i].body),
                const SizedBox(height: 5),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(notifications[i].timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}