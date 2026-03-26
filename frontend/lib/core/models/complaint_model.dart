class ComplaintModel {
  final String id;
  final String studentId;
  final StudentInfo? student;
  final String type;
  final String description;
  final String status;
  final String? adminNotes;
  final String? resolvedAt;
  final String createdAt;

  ComplaintModel({
    required this.id, required this.studentId, this.student,
    required this.type, required this.description, required this.status,
    this.adminNotes, this.resolvedAt, required this.createdAt,
  });

  String get typeIcon {
    switch (type) {
      case 'WATER': return '💧';
      case 'ELECTRICITY': return '⚡';
      case 'WIFI': return '📶';
      case 'CLEANLINESS': return '🧹';
      default: return '📋';
    }
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
    id: json['id'], studentId: json['studentId'],
    student: json['student'] != null ? StudentInfo.fromJson(json['student']) : null,
    type: json['type'] ?? 'OTHER', description: json['description'] ?? '',
    status: json['status'] ?? 'PENDING', adminNotes: json['adminNotes'],
    resolvedAt: json['resolvedAt'], createdAt: json['createdAt'] ?? '',
  );
}

class StudentInfo {
  final String name;
  final String mobile;
  final RoomInfo? room;
  StudentInfo({required this.name, required this.mobile, this.room});
  factory StudentInfo.fromJson(Map<String, dynamic> json) => StudentInfo(
    name: json['name'], mobile: json['mobile'],
    room: json['room'] != null ? RoomInfo.fromJson(json['room']) : null,
  );
}

class RoomInfo {
  final String roomNumber;
  final int floor;
  RoomInfo({required this.roomNumber, required this.floor});
  factory RoomInfo.fromJson(Map<String, dynamic> json) =>
      RoomInfo(roomNumber: json['roomNumber'], floor: json['floor'] ?? 1);
}
