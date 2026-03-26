import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class DashboardSummary {
  final int totalStudents;
  final int totalRooms;
  final int occupiedRooms;
  final int availableRooms;
  final int vacantBeds;
  final double todayRevenue;
  final double monthlyRevenue;
  final double pendingAmount;
  final int paidCount;
  final int pendingCount;
  final int openComplaints;
  final int damagedInventory;

  DashboardSummary({
    required this.totalStudents,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.availableRooms,
    required this.vacantBeds,
    required this.todayRevenue,
    required this.monthlyRevenue,
    required this.pendingAmount,
    required this.paidCount,
    required this.pendingCount,
    required this.openComplaints,
    required this.damagedInventory,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final students = json['students'] as Map<String, dynamic>? ?? {};
    final rooms = json['rooms'] as Map<String, dynamic>? ?? {};
    final fees = json['fees'] as Map<String, dynamic>? ?? {};
    final complaints = json['complaints'] as Map<String, dynamic>? ?? {};
    final inventory = json['inventory'] as Map<String, dynamic>? ?? {};

    return DashboardSummary(
      totalStudents: students['total'] ?? 0,
      totalRooms: rooms['total'] ?? 0,
      occupiedRooms: rooms['occupied'] ?? 0,
      availableRooms: rooms['available'] ?? 0,
      vacantBeds: rooms['vacantBeds'] ?? 0,
      todayRevenue: _toDouble(fees['todayRevenue']),
      monthlyRevenue: _toDouble(fees['monthlyRevenue']),
      pendingAmount: _toDouble(fees['pendingAmount']),
      paidCount: fees['paidCount'] ?? 0,
      pendingCount: fees['pendingCount'] ?? 0,
      openComplaints: complaints['open'] ?? 0,
      damagedInventory: inventory['damaged'] ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0.0;
  }
}

final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final res = await ApiClient().get('/dashboard/summary');
  return DashboardSummary.fromJson(res.data);
});
