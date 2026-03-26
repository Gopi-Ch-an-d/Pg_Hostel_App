import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/rooms_provider.dart';
import '../../core/models/student_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final _roomFilterProvider = StateProvider<Map<String, String?>>((ref) => {});

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin    = ref.watch(authProvider).user?.isAdmin ?? false;
    final canManage  = isAdmin || (ref.watch(authProvider).user?.role == 'SUPERVISOR');
    final filters    = ref.watch(_roomFilterProvider);
    final roomsAsync = ref.watch(roomsProvider(filters));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Room Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.layers_outlined, color: AppTheme.accent, size: 20),
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const FloorOverviewPage(),
              )),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => AddRoomPage(
                    onSaved: () => ref.invalidate(roomsProvider(filters))),
              )),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              tooltip: 'Add Room',
              child: const Icon(Icons.add, size: 26),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(children: [
        // ── Summary strip ──────────────────────────────────
        roomsAsync.maybeWhen(
          data: (rooms) {
            final totalRooms  = rooms.length;
            final totalBeds   = rooms.fold(0, (s, r) => s + r.capacity);
            final filledBeds  = rooms.fold(0, (s, r) => s + r.occupiedBeds);
            final freeBeds    = totalBeds - filledBeds;
            final totalFloors = rooms.map((r) => r.floor).toSet().length;

            return Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(children: [
                _SummaryPill(label: 'Floors',     value: '$totalFloors', color: AppTheme.primaryDark),
                const SizedBox(width: 6),
                _SummaryPill(label: 'Rooms',      value: '$totalRooms', color: AppTheme.accent),
                const SizedBox(width: 6),
                _SummaryPill(label: 'Total Beds', value: '$totalBeds',  color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                _SummaryPill(label: 'Filled',     value: '$filledBeds', color: AppTheme.danger),
                const SizedBox(width: 6),
                _SummaryPill(label: 'Free',       value: '$freeBeds',   color: AppTheme.primary),
              ]),
            );
          },
          orElse: () => Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              _SummaryPill(label: 'Floors',     value: '...', color: AppTheme.primaryDark),
              const SizedBox(width: 6),
              _SummaryPill(label: 'Rooms',      value: '...', color: AppTheme.accent),
              const SizedBox(width: 6),
              _SummaryPill(label: 'Total Beds', value: '...', color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              _SummaryPill(label: 'Filled',     value: '...', color: AppTheme.danger),
              const SizedBox(width: 6),
              _SummaryPill(label: 'Free',       value: '...', color: AppTheme.primary),
            ]),
          ),
        ),

        // ── Filter bar ─────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            _RoomSearchBar(
              initialValue: filters['roomNumber'] ?? '',
              onChanged: (val) => _setFilter(ref, filters, 'roomNumber', val.isEmpty ? null : val),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterChip(label: 'All',       selected: filters['status'] == null,        color: AppTheme.textSecondary,     onTap: () => _setFilter(ref, filters, 'status', null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Available', selected: filters['status'] == 'AVAILABLE', color: const Color(0xFF27500A), bg: const Color(0xFFEAF3DE), onTap: () => _setFilter(ref, filters, 'status', 'AVAILABLE')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Partial',   selected: filters['status'] == 'PARTIAL',   color: AppTheme.warning,           bg: AppTheme.warningLight, onTap: () => _setFilter(ref, filters, 'status', 'PARTIAL')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Occupied',  selected: filters['status'] == 'OCCUPIED',  color: AppTheme.danger,            bg: AppTheme.dangerLight,  onTap: () => _setFilter(ref, filters, 'status', 'OCCUPIED')),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.layers_outlined, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 6),
              const Text('Floor:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _SmallChip(label: 'All', selected: filters['floor'] == null, onTap: () => _setFilter(ref, filters, 'floor', null)),
                    ...['1','2','3','4','5','6'].map((f) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _SmallChip(label: 'F$f', selected: filters['floor'] == f, onTap: () => _setFilter(ref, filters, 'floor', f)),
                    )),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),

        Expanded(
          child: roomsAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorWidget2(
                message: 'Failed to load rooms',
                onRetry: () => ref.invalidate(roomsProvider(filters))),
            data: (rooms) => Column(children: [
              // ── Floor specific summary ─────────────────────────
              if (filters['floor'] != null) 
                _FloorSummaryRow(rooms: rooms, floor: filters['floor']!),
              
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // ── Room grid ──────────────────────────────────────
              Expanded(
                child: rooms.isEmpty
                    ? EmptyState(
                        message: 'No rooms found',
                        icon: Icons.meeting_room_outlined,
                        onAction: canManage
                            ? () => Navigator.of(context).push(MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => AddRoomPage(
                                      onSaved: () => ref.invalidate(roomsProvider(filters))),
                                ))
                            : null,
                        actionLabel: 'Add Room',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(roomsProvider(filters).future),
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: rooms.length,
                          itemBuilder: (_, i) => _RoomCard(
                            room: rooms[i],
                            isAdmin: isAdmin,
                            canManage: canManage,
                            onTap: () => _showResidentsSheet(context, rooms[i]),
                            onEdit: () => Navigator.of(context).push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => AddRoomPage(
                                room: rooms[i],
                                onSaved: () => ref.invalidate(roomsProvider(filters)),
                              ),
                            )),
                            onDelete: isAdmin
                                ? () => _confirmDelete(context, ref, rooms[i], filters)
                                : null,
                          ),
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ✅ Bottom sheet popup — shows who is staying in the room
  void _showResidentsSheet(BuildContext context, RoomBasic room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,         // allows taller sheet
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomResidentsSheet(room: room),
    );
  }

  void _setFilter(WidgetRef ref, Map<String, String?> current, String key, String? value) {
    ref.read(_roomFilterProvider.notifier).state = {...current, key: value};
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, RoomBasic room, Map<String, String?> filters) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Room'),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppTheme.dangerLight, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Room ${room.roomNumber} will be permanently deleted.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.danger))),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiClient().delete('/rooms/${room.id}');
        ref.invalidate(roomsProvider(filters));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Room deleted'),
              backgroundColor: AppTheme.primary));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
        }
      }
    }
  }
}

// ── Room Search Bar ────────────────────────────────────────────────────────
class _RoomSearchBar extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const _RoomSearchBar({this.initialValue, required this.onChanged});

  @override
  State<_RoomSearchBar> createState() => _RoomSearchBarState();
}

class _RoomSearchBarState extends State<_RoomSearchBar> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(val);
    });
    setState(() {}); // refresh for clear icon visibility
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Search Room No...',
        hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7F9),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.cancel, size: 16, color: AppTheme.textTertiary),
                onPressed: () {
                  _controller.clear();
                  _onChanged('');
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: _onChanged,
    );
  }
}

// ── Room Residents Bottom Sheet ───────────────────────────────────────────────
class _RoomResidentsSheet extends StatefulWidget {
  final RoomBasic room;
  const _RoomResidentsSheet({required this.room});

  @override
  State<_RoomResidentsSheet> createState() => _RoomResidentsSheetState();
}

class _RoomResidentsSheetState extends State<_RoomResidentsSheet> {
  bool _loading = true;
  String? _error;
  List<StudentModel> _students = [];

  Color get _accentColor {
    switch (widget.room.status) {
      case 'AVAILABLE': return const Color(0xFF1D9E75);
      case 'OCCUPIED':  return const Color(0xFFA32D2D);
      case 'PARTIAL':   return const Color(0xFFBA7517);
      default:          return AppTheme.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final res = await ApiClient().get('/rooms/${widget.room.id}');
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _students = (data['students'] as List? ?? [])
            .map((s) => StudentModel.fromJson(s))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = 'Failed to load residents';
        _loading = false;
      });
    }
  }

  Future<void> _openWhatsApp(String mobile) async {
    final phone  = mobile.replaceAll(RegExp(r'\D'), '');
    final number = phone.startsWith('91') ? phone : '91$phone';
    final uri    = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callStudent(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final vacant = widget.room.capacity - widget.room.occupiedBeds;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // ── Handle bar ────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(children: [
              // Room number badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Room ${widget.room.roomNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Floor ${widget.room.floor} • ${widget.room.capacity}-Sharing',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  '${widget.room.occupiedBeds} occupied • $vacant vacant',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: vacant == 0 ? AppTheme.danger : AppTheme.primary,
                  ),
                ),
              ]),
              const Spacer(),
              // ✅ X close button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                ),
              ),
            ]),
          ),

          // ── Bed progress bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.room.capacity > 0
                    ? widget.room.occupiedBeds / widget.room.capacity
                    : 0,
                minHeight: 8,
                backgroundColor: _accentColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Body ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: AppTheme.danger)))
                    : _students.isEmpty && vacant == widget.room.capacity
                        // Fully empty room
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bed_outlined,
                                    size: 52,
                                    color: AppTheme.textTertiary.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text('No tenants yet',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary)),
                                const SizedBox(height: 4),
                                const Text('This room is currently empty',
                                    style: TextStyle(
                                        fontSize: 12, color: AppTheme.textTertiary)),
                              ],
                            ),
                          )
                        : ListView(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: [
                              // Occupied beds
                              ..._students.asMap().entries.map((e) {
                                final idx    = e.key;
                                final student = e.value;
                                final name      = student.name;
                                final mobile    = student.mobile;
                                final feeStatus = student.latestFeeStatus;
                                final rent      = student.monthlyRent.toInt();
                                final isPaid    = feeStatus == 'PAID';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.border, width: 0.5),
                                  ),
                                  child: Column(children: [
                                    // Student info row
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(children: [
                                        // Bed badge
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: _accentColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text('B${idx + 1}',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: _accentColor)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        AvatarCircle(name: name, size: 38),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text(mobile,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary)),
                                          ]),
                                        ),
                                        // Fee badge + rent
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isPaid
                                                  ? AppTheme.primary.withOpacity(0.1)
                                                  : AppTheme.danger.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isPaid ? 'PAID' : 'DUE',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: isPaid
                                                      ? AppTheme.primary
                                                      : AppTheme.danger),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('₹$rent/mo',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textSecondary)),
                                        ]),
                                      ]),
                                    ),

                                    // Action buttons
                                    const Divider(
                                        height: 1, color: Color(0xFFEEEEEE)),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 8, 10, 10),
                                      child: Row(children: [
                                        // WhatsApp
                                        Expanded(
                                          child: _SheetBtn(
                                            faIcon: FontAwesomeIcons.whatsapp,
                                            label: 'WhatsApp',
                                            color: const Color(0xFF25D366),
                                            onTap: () =>
                                                _openWhatsApp(mobile),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Call
                                        Expanded(
                                          child: _SheetBtn(
                                            icon: Icons.call_rounded,
                                            label: 'Call',
                                            color: AppTheme.primary,
                                            onTap: () => _callStudent(mobile),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ]),
                                );
                              }),

                              // Vacant bed placeholders
                              ...List.generate(vacant, (i) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppTheme.border
                                              .withOpacity(0.5),
                                          width: 0.5),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary
                                              .withOpacity(0.06),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                              'B${_students.length + i + 1}',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.primary
                                                      .withOpacity(0.4))),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.bed_outlined,
                                          size: 22,
                                          color: AppTheme.textTertiary
                                              .withOpacity(0.4)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text('Bed vacant',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary
                                                    .withOpacity(0.6))),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text('Free',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primary
                                                    .withOpacity(0.6))),
                                      ),
                                    ]),
                                  )),
                            ],
                          ),
          ),
        ]),
      ),
    );
  }
}

// ── Sheet Action Button ───────────────────────────────────────────────────────
class _SheetBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? faIcon;

  const _SheetBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.faIcon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25), width: 0.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            faIcon != null
                ? FaIcon(faIcon!, size: 13, color: color)
                : Icon(icon!, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );
}

// ── Summary Pill ──────────────────────────────────────────────────────────────
class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2), width: 0.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

// ── Room Card ─────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomBasic room;
  final bool isAdmin;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _RoomCard({
    required this.room,
    required this.isAdmin,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  Color get _accentColor {
    switch (room.status) {
      case 'AVAILABLE': return const Color(0xFF1D9E75);
      case 'OCCUPIED':  return const Color(0xFFA32D2D);
      case 'PARTIAL':   return const Color(0xFFBA7517);
      default:          return AppTheme.textSecondary;
    }
  }

  Color get _headerBg {
    switch (room.status) {
      case 'AVAILABLE': return const Color(0xFFEAF3DE);
      case 'OCCUPIED':  return const Color(0xFFFCEBEB);
      case 'PARTIAL':   return const Color(0xFFFFF8EC);
      default:          return Colors.white;
    }
  }

  String get _statusLabel {
    switch (room.status) {
      case 'AVAILABLE': return 'Available';
      case 'OCCUPIED':  return 'Full';
      case 'PARTIAL':   return 'Partial';
      default:          return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vacantBeds = room.capacity - room.occupiedBeds;

    return GestureDetector(
      onTap: onTap,   // ✅ tapping the card opens the popup
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Coloured header
          Container(
            color: _headerBg,
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(children: [
              Expanded(
                child: Text('Room ${room.roomNumber}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _accentColor)),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w700, color: _accentColor)),
              ),
            ]),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.layers_outlined, size: 11, color: AppTheme.textTertiary),
                  const SizedBox(width: 2),
                  Text('F${room.floor}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
                  const SizedBox(width: 6),
                  const Icon(Icons.people_outline, size: 11, color: AppTheme.textTertiary),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text('${room.capacity}-Share',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: List.generate(room.capacity, (i) {
                    final isTaken = i < room.occupiedBeds;
                    return Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: isTaken ? _accentColor : _accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isTaken ? Icons.person : Icons.bed_outlined,
                        size: 11,
                        color: isTaken ? Colors.white : _accentColor.withOpacity(0.5),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${room.occupiedBeds}/${room.capacity}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const TextSpan(
                      text: ' beds • ',
                      style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                    ),
                    TextSpan(
                      text: '$vacantBeds free',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: vacantBeds == 0 ? AppTheme.danger : AppTheme.primary,
                      ),
                    ),
                  ]),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text('₹${room.monthlyRent.toInt()}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      const Text('/month',
                          style: TextStyle(fontSize: 9, color: AppTheme.textTertiary)),
                    ]),
                  ),
                  // Edit — stops tap propagation
                  if (canManage)
                    GestureDetector(
                      onTap: onEdit,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit_outlined,
                            size: 15, color: AppTheme.primaryDark),
                      ),
                    ),
                  // Delete — stops tap propagation
                  if (isAdmin && onDelete != null) ...[
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                            color: AppTheme.dangerLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline,
                            size: 15, color: AppTheme.danger),
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color? bg;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.color, this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : (bg ?? const Color(0xFFF5F5F5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color)),
        ),
      );
}

class _SmallChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SmallChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryDark : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary)),
        ),
      );
}

// ── Add / Edit Room Page ──────────────────────────────────────────────────────
class AddRoomPage extends StatefulWidget {
  final RoomBasic? room;
  final VoidCallback onSaved;
  const AddRoomPage({super.key, this.room, required this.onSaved});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final _formKey    = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _rentCtrl   = TextEditingController();
  int  _floor    = 1;
  int  _capacity = 2;
  bool _loading  = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _numberCtrl.text = widget.room!.roomNumber;
      _rentCtrl.text   = widget.room!.monthlyRent.toInt().toString();
      _floor           = widget.room!.floor;
      _capacity        = widget.room!.capacity;
    }
  }

  @override
  void dispose() { _numberCtrl.dispose(); _rentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'roomNumber': _numberCtrl.text.trim(),
        'floor': _floor,
        'capacity': _capacity,
        'monthlyRent': double.parse(_rentCtrl.text),
      };
      widget.room == null
          ? await ApiClient().post('/rooms', data: data)
          : await ApiClient().put('/rooms/${widget.room!.id}', data: data);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.room != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text(isEdit ? 'Edit Room' : 'Add Room'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        leadingWidth: 80,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _roomSectionCard(title: 'Room Details', icon: Icons.meeting_room_outlined, children: [
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  if (v.isNotEmpty) {
                    final firstCharVal = int.tryParse(v[0]);
                    if (firstCharVal != null && firstCharVal >= 1 && firstCharVal <= 8) {
                      setState(() => _floor = firstCharVal);
                    }
                  }
                },
                decoration: const InputDecoration(
                    labelText: 'Room Number', hintText: 'e.g. 101',
                    prefixIcon: Icon(Icons.tag_outlined)),
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _label('Floor Number'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: List.generate(8, (i) {
                final f = i + 1; final sel = _floor == f;
                return GestureDetector(
                  onTap: () => setState(() => _floor = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 54, height: 50,
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.border, width: sel ? 2 : 0.5),
                      boxShadow: sel ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,3))] : [],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$f', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: sel ? Colors.white : AppTheme.textSecondary)),
                      Text('Floor', style: TextStyle(fontSize: 8, color: sel ? Colors.white70 : AppTheme.textTertiary)),
                    ]),
                  ),
                );
              })),
              const SizedBox(height: 20),
              _label('Bed Capacity'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [1,2,3,4,5,6].map((c) {
                final sel = _capacity == c;
                return GestureDetector(
                  onTap: () => setState(() => _capacity = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.border, width: sel ? 2 : 0.5),
                      boxShadow: sel ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,3))] : [],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: List.generate(c > 3 ? 3 : c, (_) => Icon(Icons.bed_outlined, size: 13, color: sel ? Colors.white : AppTheme.textSecondary))),
                      const SizedBox(height: 4),
                      Text('$c bed${c > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.textSecondary)),
                    ]),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),
              TextFormField(
                controller: _rentCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Monthly Rent (₹)', hintText: 'e.g. 8000',
                    prefixIcon: Icon(Icons.currency_rupee_outlined)),
                validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid amount' : null,
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(isEdit ? 'Update Room' : 'Add Room',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary));
}

// ── Floor Overview Page ───────────────────────────────────────────────────────
class FloorOverviewPage extends ConsumerWidget {
  const FloorOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: const Text('Floor Overview'), backgroundColor: Colors.white, elevation: 0),
      body: FutureBuilder(
        future: ApiClient().get('/rooms/by-floor'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingWidget();
          if (snapshot.hasError) return const ErrorWidget2(message: 'Failed to load');
          final floors = snapshot.data!.data as List;
          if (floors.isEmpty) return const EmptyState(message: 'No floors found');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: floors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final f          = floors[i];
              final total      = (f['totalRooms']     as num).toInt();
              final occupied   = (f['occupiedRooms']  as num).toInt();
              final available  = (f['availableRooms'] as num).toInt();
              final partial    = (f['partialRooms']   as num).toInt();
              final totalBeds  = (f['totalBeds']      as num).toInt();
              final vacantBeds = (f['vacantBeds']     as num).toInt();
              final filledBeds = totalBeds - vacantBeds;
              final ratio      = totalBeds > 0 ? filledBeds / totalBeds : 0.0;

              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,3))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.centerLeft, end: Alignment.centerRight)),
                      child: Row(children: [
                        const Icon(Icons.layers_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Floor ${f['floor']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('$total rooms', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: _FloorStatCard('Occupied',  occupied,   AppTheme.danger,  Icons.lock_outline)),
                          const SizedBox(width: 8),
                          Expanded(child: _FloorStatCard('Partial',   partial,    AppTheme.warning, Icons.remove_circle_outline)),
                          const SizedBox(width: 8),
                          Expanded(child: _FloorStatCard('Available', available,  AppTheme.primary, Icons.check_circle_outline)),
                          const SizedBox(width: 8),
                          Expanded(child: _FloorStatCard('Free Beds', vacantBeds, AppTheme.accent,  Icons.bed_outlined)),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(value: ratio.clamp(0.0, 1.0), backgroundColor: const Color(0xFFEEEEEE),
                                  color: ratio >= 0.8 ? AppTheme.danger : ratio >= 0.5 ? AppTheme.warning : AppTheme.primary, minHeight: 10))),
                          const SizedBox(width: 10),
                          Text('${(ratio * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        ]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('$filledBeds/$totalBeds beds filled', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                          Text('$vacantBeds beds free', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FloorStatCard extends StatelessWidget {
  final String label; final int value; final Color color; final IconData icon;
  const _FloorStatCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary), textAlign: TextAlign.center),
        ]),
      );
}

Widget _roomSectionCard({required String title, required IconData icon, required List<Widget> children}) =>
    Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: AppTheme.primary)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );

// ── Floor Summary Row ────────────────────────────────────────────────────────
class _FloorSummaryRow extends StatelessWidget {
  final List<RoomBasic> rooms;
  final String floor;

  const _FloorSummaryRow({required this.rooms, required this.floor});

  @override
  Widget build(BuildContext context) {
    // Calculate distribution
    final Map<int, int> distribution = {};
    for (final r in rooms) {
      distribution[r.capacity] = (distribution[r.capacity] ?? 0) + 1;
    }

    final sortedKeys = distribution.keys.toList()..sort();
    final summaryItems = sortedKeys.map((cap) {
      final count = distribution[cap];
      return '$cap sharing: $count ${count == 1 ? 'room' : 'rooms'}';
    }).toList();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Floor F$floor Summary',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${rooms.length} ${rooms.length == 1 ? 'Room' : 'Rooms'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (summaryItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: summaryItems.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}