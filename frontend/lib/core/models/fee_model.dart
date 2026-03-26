class FeeModel {
  final String id;
  final String studentId;
  final StudentInfo? student;
  final int month;
  final int year;
  final double amount;
  final String dueDate;
  final String? paidDate;
  final String status;
  final String? paymentMode;
  final String? notes;

  FeeModel({
    required this.id, required this.studentId, this.student,
    required this.month, required this.year, required this.amount,
    required this.dueDate, this.paidDate, required this.status,
    this.paymentMode, this.notes,
  });

  static const monthNames = ['', 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String get monthName => monthNames[month];

  factory FeeModel.fromJson(Map<String, dynamic> json) => FeeModel(
    id: json['id'], studentId: json['studentId'],
    student: json['student'] != null ? StudentInfo.fromJson(json['student']) : null,
    month: json['month'], year: json['year'],
    amount: (json['amount'] ?? 0).toDouble(),
    dueDate: json['dueDate'] ?? '', paidDate: json['paidDate'],
    status: json['status'] ?? 'PENDING', paymentMode: json['paymentMode'], notes: json['notes'],
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
