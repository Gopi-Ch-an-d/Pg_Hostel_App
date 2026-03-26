import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  NotificationModel({required this.id, required this.title, required this.message,
    required this.type, required this.isRead, required this.createdAt});

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'], title: json['title'], message: json['message'],
    type: json['type'] ?? 'GENERAL', isRead: json['isRead'] ?? false,
    createdAt: json['createdAt'] ?? '',
  );
}

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final res = await ApiClient().get('/notifications');
  return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final res = await ApiClient().get('/notifications', params: {'unread': 'true'});
  return (res.data as List).length;
});
