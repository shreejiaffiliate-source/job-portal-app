import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationModel {
  final String title;
  final String body;
  final String jobId;
  final DateTime timestamp;

  NotificationModel({
    required this.title,
    required this.body,
    required this.jobId,
    required this.timestamp});

  // JSON mein convert karne ke liye (Saving ke liye)
  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'jobId': jobId,
    'timestamp': timestamp.toIso8601String(),
  };

  // JSON se Model banane ke liye (Loading ke liye)
  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    title: json['title'] ?? 'New Alert',
    body: json['body'] ?? '',
    jobId: json['jobId'] ?? '',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
  );
}

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => [..._notifications];

  NotificationProvider() {
    loadNotifications(); // App shuru hote hi purani notifications load karo
  }

  // --- Nayi Notification Save karo ---
  void addNotification(String title, String body, String jobId) async {
    final newNotif = NotificationModel(
      title: title,
      body: body,
      jobId: jobId,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, newNotif);
    notifyListeners();
    await _saveToDisk(); // Phone memory mein save karo
  }

  // --- Memory se Load karo ---
  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? data = prefs.getString('saved_notifications');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _notifications = jsonList.map((e) => NotificationModel.fromJson(e)).toList();
      notifyListeners();
    }
  }

  // --- Phone Memory mein Save karo ---
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_notifications.map((e) => e.toJson()).toList());
    await prefs.setString('saved_notifications', data);
  }

  // --- Saari Notifications Delete karo ---
  void clearNotifications() async {
    _notifications.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_notifications');
  }
}