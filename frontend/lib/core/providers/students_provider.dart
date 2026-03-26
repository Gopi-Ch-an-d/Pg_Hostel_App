import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/student_model.dart';

class StudentsFilter {
  final String search;
  final String? status;
  final String? floor;
  StudentsFilter({this.search = '', this.status, this.floor});
  StudentsFilter copyWith({String? search, String? status, String? floor}) =>
      StudentsFilter(search: search ?? this.search, status: status, floor: floor);
}

final studentsFilterProvider = StateProvider<StudentsFilter>((ref) => StudentsFilter());

final studentsProvider = FutureProvider.autoDispose<List<StudentModel>>((ref) async {
  final filter = ref.watch(studentsFilterProvider);
  final params = <String, dynamic>{};
  if (filter.search.isNotEmpty) params['search'] = filter.search;
  if (filter.status != null) params['status'] = filter.status;
  if (filter.floor != null) params['floor'] = filter.floor;
  final res = await ApiClient().get('/students', params: params);
  return (res.data['data'] as List).map((e) => StudentModel.fromJson(e)).toList();
});

final studentDetailProvider = FutureProvider.autoDispose.family<StudentModel, String>((ref, id) async {
  final res = await ApiClient().get('/students/$id');
  return StudentModel.fromJson(res.data);
});
