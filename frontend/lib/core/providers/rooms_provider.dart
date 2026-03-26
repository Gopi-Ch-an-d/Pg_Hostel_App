import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/student_model.dart';

final roomsProvider = FutureProvider.autoDispose.family<List<RoomBasic>, Map<String, String?>>((ref, filters) async {
  final params = <String, dynamic>{};
  if (filters['floor'] != null) params['floor'] = filters['floor'];
  if (filters['status'] != null) params['status'] = filters['status'];
  if (filters['roomNumber'] != null) params['roomNumber'] = filters['roomNumber'];
  final res = await ApiClient().get('/rooms', params: params);
  return (res.data as List).map((e) => RoomBasic.fromJson(e)).toList();
});

final roomSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiClient().get('/rooms/summary');
  return res.data;
});
