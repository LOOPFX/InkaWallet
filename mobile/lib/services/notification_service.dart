import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'transaction', 'system', 'promotional', 'alert'
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
      'data': data,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  Future<void> initialize() async {
    await _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    
    _notifications.clear();
    for (var jsonStr in notificationsJson) {
      try {
        final json = Map<String, dynamic>.from(
          Map.fromIterables(
            jsonStr.split('|||').asMap().keys,
            jsonStr.split('|||'),
          ),
        );
        _notifications.add(NotificationModel.fromJson(json));
      } catch (e) {
        debugPrint('Error parsing notification: $e');
      }
    }
    
    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }
  
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications.map((n) {
      final json = n.toJson();
      return json.values.join('|||');
    }).toList();
    
    await prefs.setStringList('notifications', notificationsJson);
  }
  
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      data: data,
    );
    
    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }
  
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
  
  IconData getIconForType(String type) {
    switch (type) {
      case 'transaction':
        return Icons.receipt;
      case 'system':
        return Icons.info;
      case 'promotional':
        return Icons.star;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }
  
  Color getColorForType(String type) {
    switch (type) {
      case 'transaction':
        return Colors.blue;
      case 'system':
        return Colors.grey;
      case 'promotional':
        return Colors.orange;
      case 'alert':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
}
