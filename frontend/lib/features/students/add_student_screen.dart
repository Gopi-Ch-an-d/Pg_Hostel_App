import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/student_model.dart';
import '../../core/theme/app_theme.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  final String? studentId;
  const AddStudentScreen({super.key, this.studentId});
  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _aadhaar = TextEditingController();
  final _address = TextEditingController();
  final _deposit = TextEditingController();
  final _rent = TextEditingController();
  final _vehicleNumber = TextEditingController();
  String? _vehicleType;
  DateTime? _joiningDate;
  String? _selectedRoomId;
  int? _selectedFloor;
  List<RoomBasic> _rooms = [];
  Map<int, List<RoomBasic>> _roomsByFloor = {};
  bool _loading = false;
  bool _loadingRooms = true;
  XFile? _idProofFile;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    if (widget.studentId != null) _loadStudent();
  }

  @override
  void dispose() {
    _name.dispose(); _mobile.dispose(); _aadhaar.dispose();
    _address.dispose(); _deposit.dispose(); _rent.dispose();
    _vehicleNumber.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _loadingRooms = true);
    try {
      final res = await ApiClient().get('/students/available-rooms');
      final rooms = (res.data as List).map((e) => RoomBasic.fromJson(e)).toList();
      final Map<int, List<RoomBasic>> grouped = {};
      for (final r in rooms) {
        grouped.putIfAbsent(r.floor, () => []).add(r);
      }
      setState(() { _rooms = rooms; _roomsByFloor = grouped; _loadingRooms = false; });
    } catch (_) { setState(() => _loadingRooms = false); }
  }

  Future<void> _loadStudent() async {
    try {
      final res = await ApiClient().get('/students/${widget.studentId}');
      final s = StudentModel.fromJson(res.data);
      setState(() {
        _name.text = s.name;
        _mobile.text = s.mobile;
        _aadhaar.text = s.aadhaar ?? '';
        _address.text = s.address;
        _deposit.text = s.deposit.toInt().toString();
        _rent.text = s.monthlyRent.toInt().toString();
        _joiningDate = DateTime.tryParse(s.joiningDate);
        _selectedRoomId = s.roomId;
        _vehicleNumber.text = s.vehicleNumber ?? '';
        _vehicleType = s.vehicleType;
      });
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) setState(() => _idProofFile = file);
    } catch (_) { _showError('Could not pick image'); }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_joiningDate == null) { _showError('Please select joining date'); return; }
    if (_selectedRoomId == null && widget.studentId == null) { _showError('Please select a room'); return; }

    setState(() => _loading = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'mobile': _mobile.text.trim(),
        'aadhaar': _aadhaar.text.trim(),
        'address': _address.text.trim(),
        'roomId': _selectedRoomId,
        'joiningDate': _joiningDate!.toIso8601String(),
        'deposit': double.parse(_deposit.text),
        'monthlyRent': double.parse(_rent.text),
        if (_vehicleNumber.text.isNotEmpty) 'vehicleNumber': _vehicleNumber.text.trim().toUpperCase(),
        if (_vehicleType != null) 'vehicleType': _vehicleType,
      };

      if (widget.studentId == null) {
        final res = await ApiClient().post('/students', data: data);
        if (_idProofFile != null && !kIsWeb) {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(_idProofFile!.path, filename: _idProofFile!.name),
          });
          await ApiClient().postFormData('/students/${res.data['id']}/upload-id', formData);
        }
        _showSuccess('Tenant added successfully');
      } else {
        await ApiClient().put('/students/${widget.studentId}', data: data);
        _showSuccess('Tenant updated successfully');
      }
      if (mounted) context.pop();
    } catch (e) {
      _showError('Error: ${e.toString()}');
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.danger));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.primary));

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.studentId != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(isEdit ? 'Edit Tenant' : 'Add Tenant')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [

            // ── 1. Personal Details ───────────────────────────────
            _SectionCard(
              title: 'Personal Details',
              icon: Icons.person_outline,
              children: [
                _field('Full Name', _name, Icons.person_outline,
                    hint: 'e.g. Rahul Kumar',
                    validator: (v) => (v ?? '').isEmpty ? 'Name is required' : null),
                _field('Mobile Number', _mobile, Icons.phone_outlined,
                    hint: '10-digit mobile number',
                    keyboard: TextInputType.phone,
                    validator: (v) => (v ?? '').length != 10 ? 'Enter valid 10-digit number' : null),
                _field('Aadhaar Number (Optional)', _aadhaar, Icons.credit_card_outlined,
                    hint: 'XXXX XXXX XXXX',
                    keyboard: TextInputType.number),
                // ✅ Address — mandatory
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextFormField(
                    controller: _address,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Home Address *',
                      hintText: 'House No, Street, City, State, PIN',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 32),
                        child: Icon(Icons.home_outlined),
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Address is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── 2. Room Selection — grouped by floor ──────────────
            if (!isEdit)
              _SectionCard(
                title: 'Select Room',
                icon: Icons.meeting_room_outlined,
                children: [
                  if (_loadingRooms)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_rooms.isEmpty)
                    _infoBox('No rooms available currently', AppTheme.danger, Icons.warning_amber_outlined)
                  else ...[
                    // 1. Floor Selector
                    DropdownButtonFormField<int?>(
                      value: _selectedFloor,
                      decoration: const InputDecoration(
                        labelText: 'Select Floor',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      items: [
                         const DropdownMenuItem(value: null, child: Text('Choose a floor')),
                         ...(_roomsByFloor.keys.toList()..sort()).map((f) => 
                            DropdownMenuItem(value: f, child: Text('Floor $f'))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedFloor = v;
                        _selectedRoomId = null; // reset room when floor changes
                      }),
                    ),
                    
                    const SizedBox(height: 16),

                    // 2. Room Selector (only if floor picked)
                    if (_selectedFloor == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Select a floor to see available rooms', 
                              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                        ),
                      )
                    else ...[
                      Row(children: [
                        const Icon(Icons.meeting_room_outlined, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text('Available Rooms on Floor $_selectedFloor', 
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ]),
                      const SizedBox(height: 10),
                      ...(_roomsByFloor[_selectedFloor!] ?? []).map((room) => _RoomTile(
                        room: room,
                        isSelected: _selectedRoomId == room.id,
                        onTap: room.vacantBeds == 0 ? null : () => setState(() {
                          _selectedRoomId = room.id;
                          _rent.text = room.monthlyRent.toInt().toString();
                        }),
                      )),
                    ],
                  ],
                ],
              ),
            if (!isEdit) const SizedBox(height: 14),

            // ── 3. Financial Details ──────────────────────────────
            _SectionCard(
              title: 'Financial Details',
              icon: Icons.currency_rupee_outlined,
              children: [
                // Joining date
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _joiningDate ?? DateTime.now(),
                      firstDate: DateTime(2020), lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _joiningDate = d);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _joiningDate != null ? AppTheme.primary : AppTheme.border,
                        width: _joiningDate != null ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined, size: 18,
                          color: _joiningDate != null ? AppTheme.primary : AppTheme.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _joiningDate != null
                              ? DateFormat('dd MMMM yyyy').format(_joiningDate!)
                              : 'Select Joining Date *',
                          style: TextStyle(fontSize: 14,
                              color: _joiningDate != null ? AppTheme.textPrimary : AppTheme.textTertiary),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down,
                          color: _joiningDate != null ? AppTheme.primary : AppTheme.textTertiary),
                    ]),
                  ),
                ),
                Row(children: [
                  Expanded(child: _field('Deposit (₹) *', _deposit, Icons.savings_outlined,
                      hint: 'e.g. 16000',
                      keyboard: TextInputType.number,
                      validator: (v) => (v ?? '').isEmpty ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Monthly Rent (₹) *', _rent, Icons.currency_rupee_outlined,
                      hint: 'e.g. 8000',
                      keyboard: TextInputType.number,
                      validator: (v) => (v ?? '').isEmpty ? 'Required' : null)),
                ]),
              ],
            ),
            const SizedBox(height: 14),

            // ── 4. Vehicle Details — Optional ─────────────────────
            _SectionCard(
              title: 'Vehicle Details',
              icon: Icons.two_wheeler_outlined,
              // ✅ Fixed: badge in Column, not Row — no overflow
              badge: 'Optional',
              children: [
                const Text('Vehicle Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                // ✅ Wrap prevents overflow on small screens
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Bike', 'Scooter', 'Car', 'Bicycle', 'None'].map((type) {
                    final sel = _vehicleType == type || (type == 'None' && _vehicleType == null);
                    return GestureDetector(
                      onTap: () => setState(() => _vehicleType = type == 'None' ? null : type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : AppTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_vehicleIcon(type), style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(type,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : AppTheme.textSecondary)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                if (_vehicleType != null) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _vehicleNumber,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Number',
                      hintText: 'e.g. TS09AB1234',
                      prefixIcon: const Icon(Icons.confirmation_number_outlined),
                      suffixIcon: _vehicleNumber.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _vehicleNumber.clear()),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // ── 5. ID Proof — Optional ────────────────────────────
            _SectionCard(
              title: 'ID Proof',
              icon: Icons.badge_outlined,
              badge: 'Optional',
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _idProofFile != null ? AppTheme.primaryLight : AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _idProofFile != null ? AppTheme.primary : AppTheme.border,
                        width: _idProofFile != null ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(children: [
                      Icon(_idProofFile != null ? Icons.check_circle_outline : Icons.add_photo_alternate_outlined,
                          color: _idProofFile != null ? AppTheme.primary : AppTheme.textTertiary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        _idProofFile != null ? _idProofFile!.name : 'Tap to upload Aadhaar / ID photo',
                        style: TextStyle(fontSize: 13,
                            color: _idProofFile != null ? AppTheme.primaryDark : AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      )),
                      if (_idProofFile != null)
                        GestureDetector(
                          onTap: () => setState(() => _idProofFile = null),
                          child: const Icon(Icons.close, size: 18, color: AppTheme.textTertiary),
                        ),
                    ]),
                  ),
                ),
                if (_idProofFile != null && !kIsWeb) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_idProofFile!.path),
                        height: 130, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // ── Submit button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(isEdit ? 'Update Tenant' : 'Add Tenant',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  String _vehicleIcon(String type) {
    switch (type) {
      case 'Bike': return '🏍️';
      case 'Scooter': return '🛵';
      case 'Car': return '🚗';
      case 'Bicycle': return '🚲';
      default: return '🚫';
    }
  }

  Widget _infoBox(String msg, Color color, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: color))),
    ]),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {String? hint, TextInputType? keyboard, String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
          validator: validator,
        ),
      );
}

// ── Room Tile ─────────────────────────────────────────────────────────────────
class _RoomTile extends StatelessWidget {
  final RoomBasic room;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RoomTile({required this.room, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFull = room.vacantBeds == 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight
              : isFull ? const Color(0xFFFCEBEB) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : isFull ? const Color(0xFFF09595) : AppTheme.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          // Bed dots column
          Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.meeting_room_outlined, size: 18,
                color: isSelected ? AppTheme.primary : isFull ? AppTheme.danger : AppTheme.textSecondary),
            const SizedBox(height: 5),
            Row(children: List.generate(room.capacity, (i) => Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < room.occupiedBeds ? AppTheme.danger : AppTheme.primary,
              ),
            ))),
          ]),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Room ${room.roomNumber}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(
              isFull ? 'Full — no beds available'
                  : '${room.vacantBeds} of ${room.capacity} beds free',
              style: TextStyle(fontSize: 11,
                  color: isFull ? AppTheme.danger
                      : isSelected ? AppTheme.primary : AppTheme.textSecondary),
            ),
            if (room.students.isNotEmpty && !isFull) ...[
              const SizedBox(height: 2),
              Text(
                'With: ${room.students.map((s) => (s['name'] as String).split(' ').first).join(', ')}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ])),
          // Rent + checkmark
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Text('₹${room.monthlyRent.toInt()}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary)),
            const Text('/mo', style: TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final List<Widget> children;

  const _SectionCard({
    required this.title, required this.icon,
    this.badge, required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // ✅ Title row — badge in a separate line to avoid overflow
        Row(children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Text(badge!,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.w500)),
            ),
          ],
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }
}