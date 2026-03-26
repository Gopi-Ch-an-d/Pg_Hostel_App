import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int total;
  final int good;
  final int damaged;
  final int missing;
  final String? notes;

  InventoryItem({required this.id, required this.name, required this.category,
    required this.total, required this.good, required this.damaged,
    required this.missing, this.notes});

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'], name: json['name'], category: json['category'],
    total: json['total'] ?? 0, good: json['good'] ?? 0,
    damaged: json['damaged'] ?? 0, missing: json['missing'] ?? 0, notes: json['notes'],
  );
}

final inventoryProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) async {
  final res = await ApiClient().get('/inventory');
  return (res.data as List).map((e) => InventoryItem.fromJson(e)).toList();
});
