import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/accessibility_service.dart';
import '../widgets/voice_enabled_screen.dart';
import '../widgets/voice_enabled_screen.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _accessibility = AccessibilityService();

  @override
  void initState() {
    super.initState();
    _accessibility.speak('Notifications screen');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: NotificationService(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color(0xFF7C3AED),
          actions: [
            Consumer<NotificationService>(
              builder: (context, notificationService, _) {
                if (notificationService.notifications.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Text('Mark all as read'),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear all'),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'mark_all_read') {
                      await notificationService.markAllAsRead();
                      _accessibility.speak('All notifications marked as read');
                    } else if (value == 'clear_all') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Notifications'),
                          content: const Text('Are you sure you want to delete all notifications?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        await notificationService.clearAll();
                        _accessibility.speak('All notifications cleared');
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Consumer<NotificationService>(
          builder: (context, notificationService, _) {
            if (notificationService.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: notificationService.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationService.notifications[index];
                return _buildNotificationItem(notification, notificationService);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationService service,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        service.deleteNotification(notification.id);
        _accessibility.speak('Notification deleted');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: notification.isRead ? null : Colors.blue.withOpacity(0.1),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: service.getColorForType(notification.type),
            child: Icon(
              service.getIconForType(notification.type),
              color: Colors.white,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () async {
            if (!notification.isRead) {
              await service.markAsRead(notification.id);
            }
            
            _accessibility.speak('${notification.title}. ${notification.message}');
            
            // Handle notification tap based on type
            if (notification.data != null) {
              // Navigate to relevant screen based on data
              debugPrint('Notification data: ${notification.data}');
            }
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}
