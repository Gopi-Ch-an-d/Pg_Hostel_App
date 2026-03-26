class StudentModel {
  final String id;
  final String name;
  final String mobile;
  final String? aadhaar;
  final String address;
  final String roomId;
  final RoomBasic? room;
  final String joiningDate;
  final double deposit;
  final double monthlyRent;
  final String? idProofUrl;
  final String? vehicleNumber;
  final String? vehicleType;
  final bool isActive;
  final List<FeeBasic> fees;

  StudentModel({
    required this.id, required this.name, required this.mobile,
    this.aadhaar, required this.address, required this.roomId,
    this.room, required this.joiningDate, required this.deposit,
    required this.monthlyRent, this.idProofUrl,
    this.vehicleNumber, this.vehicleType,
    required this.isActive, this.fees = const [],
  });

  bool get hasVehicle => vehicleNumber != null && vehicleNumber!.isNotEmpty;
  String get latestFeeStatus => fees.isNotEmpty ? fees.first.status : 'PENDING';

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    id: json['id'],
    name: json['name'],
    mobile: json['mobile'],
    aadhaar: json['aadhaar'],
    address: json['address'] ?? '',
    roomId: json['roomId'],
    room: json['room'] != null ? RoomBasic.fromJson(json['room']) : null,
    joiningDate: json['joiningDate'] ?? '',
    deposit: (json['deposit'] ?? 0).toDouble(),
    monthlyRent: (json['monthlyRent'] ?? 0).toDouble(),
    idProofUrl: json['idProofUrl'],
    vehicleNumber: json['vehicleNumber'],
    vehicleType: json['vehicleType'],
    isActive: json['isActive'] ?? true,
    fees: (json['fees'] as List? ?? []).map((f) => FeeBasic.fromJson(f)).toList(),
  );
}

class RoomBasic {
  final String id;
  final String roomNumber;
  final int floor;
  final int capacity;
  final int occupiedBeds;
  final String status;
  final double monthlyRent;
  final List<dynamic> students;

  RoomBasic({
    required this.id, required this.roomNumber, required this.floor,
    required this.capacity, required this.occupiedBeds,
    required this.status, required this.monthlyRent,
    this.students = const [],
  });

  int get vacantBeds => capacity - occupiedBeds;
  bool get isAvailable => status == 'AVAILABLE' || status == 'PARTIAL';

  factory RoomBasic.fromJson(Map<String, dynamic> json) => RoomBasic(
    id: json['id'],
    roomNumber: json['roomNumber'],
    floor: json['floor'] ?? 1,
    capacity: json['capacity'] ?? 2,
    occupiedBeds: json['occupiedBeds'] ?? 0,
    status: json['status'] ?? 'AVAILABLE',
    monthlyRent: (json['monthlyRent'] ?? 0).toDouble(),
    students: json['students'] as List? ?? [],
  );
}

class FeeBasic {
  final String id;
  final int month;
  final int year;
  final double amount;
  final String status;
  final String? paidDate;

  FeeBasic({required this.id, required this.month, required this.year,
    required this.amount, required this.status, this.paidDate});

  factory FeeBasic.fromJson(Map<String, dynamic> json) => FeeBasic(
    id: json['id'], month: json['month'], year: json['year'],
    amount: (json['amount'] ?? 0).toDouble(),
    status: json['status'] ?? 'PENDING',
    paidDate: json['paidDate'],
  );
}