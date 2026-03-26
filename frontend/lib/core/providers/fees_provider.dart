import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/fee_model.dart';

final historyFiltersProvider = StateProvider.autoDispose<Map<String, int>>((ref) {
  final now = DateTime.now();
  return {'month': now.month, 'year': now.year};
});

final monthlyFiltersProvider = StateProvider.autoDispose<Map<String, int>>((ref) {
  final now = DateTime.now();
  return {'month': now.month, 'year': now.year};
});

final currentMonthFeesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final filters = ref.watch(monthlyFiltersProvider);
  final res = await ApiClient().get('/fees/monthly', params: {
    'month': filters['month'].toString(),
    'year': filters['year'].toString()
  });
  return res.data;
});

final historyFeesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final filters = ref.watch(historyFiltersProvider);
  final res = await ApiClient().get('/fees/monthly', params: {
    'month': filters['month'].toString(),
    'year': filters['year'].toString()
  });
  return res.data;
});

final pendingFeesProvider = FutureProvider.autoDispose<List<FeeModel>>((ref) async {
  final res = await ApiClient().get('/fees/pending');
  return (res.data as List).map((e) => FeeModel.fromJson(e)).toList();
});

final studentFeesProvider = FutureProvider.autoDispose.family<List<FeeModel>, String>((ref, studentId) async {
  final res = await ApiClient().get('/fees/student/$studentId');
  return (res.data as List).map((e) => FeeModel.fromJson(e)).toList();
});
