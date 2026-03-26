import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/complaint_model.dart';

final complaintsFilterProvider = StateProvider<String?>((ref) => null);

final complaintsProvider = FutureProvider.autoDispose<List<ComplaintModel>>((ref) async {
  final status = ref.watch(complaintsFilterProvider);
  final params = <String, dynamic>{};
  if (status != null) params['status'] = status;
  final res = await ApiClient().get('/complaints', params: params);
  return (res.data as List).map((e) => ComplaintModel.fromJson(e)).toList();
});

final minimalStudentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient().get('/students/minimal');
  return List<Map<String, dynamic>>.from(res.data);
});
