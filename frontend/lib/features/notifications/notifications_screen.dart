import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/notifications_provider.dart';
import '../../core/providers/students_provider.dart';
import '../../core/models/student_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Inbox'), Tab(text: 'Send WhatsApp')],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiClient().put('/notifications/mark-all-read', data: {});
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Read all', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _InboxTab(),
          isAdmin ? _WhatsAppTab() : const Center(child: Text('Admin only')),
        ],
      ),
    );
  }
}

// ── Inbox Tab ─────────────────────────────────────────────────────────────────
class _InboxTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return async.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorWidget2(message: 'Failed to load', onRetry: () => ref.invalidate(notificationsProvider)),
      data: (notifications) => notifications.isEmpty
          ? const EmptyState(message: 'No notifications yet', icon: Icons.notifications_none)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotifCard(
                n: notifications[i],
                onRead: () async {
                  await ApiClient().put('/notifications/${notifications[i].id}/read', data: {});
                  ref.invalidate(notificationsProvider);
                },
              ),
            ),
    );
  }
}

// ── WhatsApp Tab ──────────────────────────────────────────────────────────────
class _WhatsAppTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WhatsAppTab> createState() => _WhatsAppTabState();
}

class _WhatsAppTabState extends ConsumerState<_WhatsAppTab> {
  // Mode: 'single' or 'bulk'
  String _mode = 'bulk';

  // Bulk options
  String _target = 'all';    // all, floor, pending
  int? _selectedFloor;
  final _msgCtrl    = TextEditingController();
  final _titleCtrl  = TextEditingController();

  // Single student
  StudentModel? _selectedStudent;
  final _singleMsgCtrl = TextEditingController();

  bool _sending = false;
  Map<String, dynamic>? _lastResult;

  @override
  void dispose() { _msgCtrl.dispose(); _titleCtrl.dispose(); _singleMsgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── Mode toggle ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Row(children: [
            Expanded(child: _ModeBtn(label: '👤 Single Person', selected: _mode == 'single', onTap: () => setState(() => _mode = 'single'))),
            Expanded(child: _ModeBtn(label: '👥 Bulk Message', selected: _mode == 'bulk', onTap: () => setState(() => _mode = 'bulk'))),
          ]),
        ),
        const SizedBox(height: 16),

        if (_mode == 'single') _buildSingleMode()
        else _buildBulkMode(),

        // ── Result ────────────────────────────────────────────
        if (_lastResult != null) ...[
          const SizedBox(height: 16),
          _ResultCard(result: _lastResult!),
        ],
      ]),
    );
  }

  // ── SINGLE MODE ───────────────────────────────────────────────────────────
  Widget _buildSingleMode() {
    final studentsAsync = ref.watch(studentsProvider);
    return Column(children: [
      // WhatsApp info box
      _infoBox('💬 Send WhatsApp directly to one student\'s mobile number', AppTheme.accent),
      const SizedBox(height: 14),

      // Student selector
      _sectionCard('Select Student', [
        studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Text('Failed to load students'),
          data: (students) => DropdownButtonFormField<StudentModel>(
            initialValue: _selectedStudent,
            isExpanded: true,
            hint: const Text('Choose a student'),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_search_outlined)),
            items: students.map((s) => DropdownMenuItem(
              value: s,
              child: Text(
                '${s.name} — Room ${s.room?.roomNumber ?? ''} (${s.mobile})',
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (v) {
              setState(() => _selectedStudent = v);
              if (v != null) {
                _singleMsgCtrl.text =
                    'Hi ${v.name}, this is a message from PG Management.';
              }
            },
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Student info card
      if (_selectedStudent != null)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            AvatarCircle(name: _selectedStudent!.name, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selectedStudent!.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
              Text('📱 ${_selectedStudent!.mobile}', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
              Text('🏠 Room ${_selectedStudent!.room?.roomNumber ?? ''} — Floor ${_selectedStudent!.room?.floor ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
            ])),
          ]),
        ),
      const SizedBox(height: 12),

      // Message
      _sectionCard('Message', [
        TextFormField(
          controller: _singleMsgCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type your WhatsApp message here...',
            alignLabelWithHint: true,
            border: InputBorder.none,
          ),
        ),
        // Quick templates
        const Divider(),
        const Text('Quick templates:', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _TemplateChip('Fee Reminder', () {
            if (_selectedStudent == null) return;
            _singleMsgCtrl.text = '🏠 *Fee Reminder*\n\nHi *${_selectedStudent!.name}*, your rent is due.\n\nAmount: ₹${_selectedStudent!.monthlyRent.toInt()}\nPlease pay at the earliest.\n\nThank you! 🙏';
            setState(() {});
          }),
          _TemplateChip('Welcome', () {
            if (_selectedStudent == null) return;
            _singleMsgCtrl.text = '🏠 *Welcome to Our PG!*\n\nHi *${_selectedStudent!.name}*, welcome!\n\nRoom: ${_selectedStudent!.room?.roomNumber ?? ''}\nRent: ₹${_selectedStudent!.monthlyRent.toInt()}/month\n\nContact management for any help. 😊';
            setState(() {});
          }),
          _TemplateChip('Maintenance', () {
            _singleMsgCtrl.text = '🏠 *Maintenance Notice*\n\nDear Student,\n\nMaintenance work is scheduled. Please cooperate.\n\nThank you!';
            setState(() {});
          }),
        ]),
      ]),
      const SizedBox(height: 16),

      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton.icon(
          onPressed: (_sending || _selectedStudent == null || _singleMsgCtrl.text.isEmpty)
              ? null : _sendSingle,
          icon: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('📱', style: TextStyle(fontSize: 18)),
          label: Text(_sending ? 'Sending...' : 'Send WhatsApp',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  // ── BULK MODE ─────────────────────────────────────────────────────────────
  Widget _buildBulkMode() {
    return Column(children: [
      _infoBox('📢 Send one message to multiple students at once', const Color(0xFF25D366)),
      const SizedBox(height: 14),

      // Target selector
      _sectionCard('Send To', [
        const Text('Who should receive this message?',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _TargetChip(label: '🏠 All Students', selected: _target == 'all', onTap: () => setState(() { _target = 'all'; _selectedFloor = null; })),
          _TargetChip(label: '⚠️ Pending Fees Only', selected: _target == 'pending', onTap: () => setState(() { _target = 'pending'; _selectedFloor = null; })),
          _TargetChip(label: '🏢 By Floor', selected: _target == 'floor', onTap: () => setState(() => _target = 'floor')),
        ]),
        if (_target == 'floor') ...[
          const SizedBox(height: 12),
          const Text('Select Floor:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [1,2,3,4,5].map((f) {
            final sel = _selectedFloor == f;
            return GestureDetector(
              onTap: () => setState(() => _selectedFloor = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48, height: 42,
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$f', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.textSecondary)),
                  Text('Floor', style: TextStyle(fontSize: 8, color: sel ? Colors.white70 : AppTheme.textTertiary)),
                ]),
              ),
            );
          }).toList()),
        ],
      ]),
      const SizedBox(height: 12),

      // Message title
      _sectionCard('Notification Title', [
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Food Delay Notice',
            prefixIcon: Icon(Icons.title_outlined),
            border: InputBorder.none,
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Message body
      _sectionCard('WhatsApp Message', [
        TextFormField(
          controller: _msgCtrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Type your message here...\nYou can use *bold* for WhatsApp formatting',
            alignLabelWithHint: true,
            border: InputBorder.none,
          ),
        ),
        const Divider(),
        const Text('Quick templates:', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _TemplateChip('🍽️ Food Delay', () {
            _titleCtrl.text = 'Food Delay Notice';
            _msgCtrl.text = '🏠 *PG Hostel Notice*\n\n🍽️ *Food Delay Alert*\n\nDear Students,\n\nToday\'s food will be delayed by approximately *30-45 minutes*.\n\nWe apologize for the inconvenience.\n\nThank you for your patience! 🙏';
            setState(() {});
          }),
          _TemplateChip('💰 Fee Reminder', () {
            _titleCtrl.text = 'Monthly Fee Reminder';
            _msgCtrl.text = '🏠 *PG Hostel Fee Reminder*\n\nDear Students,\n\nThis is a reminder that your monthly rent is due.\n\n📅 Due Date: 5th of this month\n\nPlease pay at the earliest to avoid late fees.\n\nThank you! 🙏';
            setState(() {});
          }),
          _TemplateChip('🔧 Maintenance', () {
            _titleCtrl.text = 'Maintenance Notice';
            _msgCtrl.text = '🏠 *Maintenance Notice*\n\nDear Students,\n\nMaintenance work will be carried out tomorrow.\n\n🔧 *Water supply* may be interrupted from 10AM - 2PM.\n\nPlease store water accordingly.\n\nSorry for the inconvenience! 🙏';
            setState(() {});
          }),
          _TemplateChip('⚡ Power Cut', () {
            _titleCtrl.text = 'Power Cut Notice';
            _msgCtrl.text = '🏠 *Power Cut Notice*\n\nDear Students,\n\n⚡ There will be a *power cut* today from *2PM to 5PM* for maintenance work.\n\nPlease plan accordingly.\n\nThank you! 🙏';
            setState(() {});
          }),
          _TemplateChip('🎉 Holiday', () {
            _titleCtrl.text = 'Holiday Notice';
            _msgCtrl.text = '🏠 *PG Hostel Notice*\n\n🎉 Wishing you a Happy Holiday!\n\nKindly note that the office will be closed tomorrow.\n\nFor emergencies, contact: [your number]\n\nHappy Holidays! 🎊';
            setState(() {});
          }),
          _TemplateChip('🚿 Water Supply', () {
            _titleCtrl.text = 'Water Supply Notice';
            _msgCtrl.text = '🏠 *Water Supply Notice*\n\nDear Students,\n\n🚿 Hot water will be available from *6AM - 10AM* and *5PM - 9PM* daily.\n\nPlease plan your schedules accordingly.\n\nThank you! 🙏';
            setState(() {});
          }),
        ]),
      ]),
      const SizedBox(height: 16),

      // Warning box before sending
      if (_target == 'all')
        _infoBox('⚠️ Sends to ALL active students', AppTheme.warning),
      if (_target == 'pending')
        _infoBox('💰 Only pending-fee students receive this', AppTheme.warning),
      if (_target == 'floor' && _selectedFloor != null)
        _infoBox('🏢 Only Floor $_selectedFloor students will receive this', AppTheme.accent),
      const SizedBox(height: 12),

      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton.icon(
          onPressed: (_sending || _msgCtrl.text.isEmpty) ? null : _sendBulk,
          icon: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('📢', style: TextStyle(fontSize: 18)),
          label: Text(
            _sending ? 'Sending...' : 'Send to All',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  String _targetLabel() {
    if (_target == 'all') return 'All Students';
    if (_target == 'pending') return 'Pending Students';
    if (_target == 'floor' && _selectedFloor != null) return 'Floor $_selectedFloor';
    return 'Selected';
  }

  Future<void> _sendSingle() async {
    if (_selectedStudent == null || _singleMsgCtrl.text.isEmpty) return;
    setState(() { _sending = true; _lastResult = null; });
    try {
      final res = await ApiClient().post(
        '/notifications/whatsapp/student/${_selectedStudent!.id}',
        data: {'message': _singleMsgCtrl.text},
      );
      setState(() { _lastResult = res.data; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.data['success'] == true
              ? '✅ WhatsApp sent to ${_selectedStudent!.name}!'
              : '❌ Failed: ${res.data['error']}'),
          backgroundColor: res.data['success'] == true ? AppTheme.primary : AppTheme.danger,
        ),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _sendBulk() async {
    if (_msgCtrl.text.isEmpty) return;
    if (_target == 'floor' && _selectedFloor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a floor'), backgroundColor: AppTheme.warning));
      return;
    }

    // Confirm before bulk send
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Bulk Send'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Send WhatsApp to: *${_targetLabel()}*', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.surfaceSecondary, borderRadius: BorderRadius.circular(8)),
            child: Text(_msgCtrl.text, style: const TextStyle(fontSize: 12)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { _sending = true; _lastResult = null; });
    try {
      final res = await ApiClient().post('/notifications/whatsapp/bulk', data: {
        'message': _msgCtrl.text,
        'title': _titleCtrl.text.isEmpty ? 'Bulk Message' : _titleCtrl.text,
        'targetAll': _target == 'all',
        if (_target == 'floor' && _selectedFloor != null) 'floor': _selectedFloor,
        if (_target == 'pending') 'onlyPending': true,
      });
      setState(() { _lastResult = res.data; });
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  Widget _infoBox(String msg, Color color) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
    child: Row(children: [
      Expanded(
        child: Text(msg, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    ]),
  );

  Widget _sectionCard(String title, List<Widget> children) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
      ),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    ]),
  );
}

// ── Result Card ───────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final sent   = result['sent'] ?? 0;
    final failed = result['failed'] ?? 0;
    final total  = result['total'] ?? (sent + failed);
    final success = result['success'];

    // Single send result
    if (success != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: success == true ? AppTheme.primaryLight : AppTheme.dangerLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(success == true ? Icons.check_circle : Icons.error_outline,
              color: success == true ? AppTheme.primary : AppTheme.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(
            success == true ? 'WhatsApp sent successfully!' : 'Failed: ${result['error']}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: success == true ? AppTheme.primaryDark : AppTheme.danger),
          )),
        ]),
      );
    }

    // Bulk result
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Bulk Send Result', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ResultStat('Total', '$total', AppTheme.accent)),
          const SizedBox(width: 8),
          Expanded(child: _ResultStat('Sent ✅', '$sent', AppTheme.primary)),
          const SizedBox(width: 8),
          Expanded(child: _ResultStat('Failed ❌', '$failed', failed > 0 ? AppTheme.danger : AppTheme.textTertiary)),
        ]),
        if (failed > 0 && result['errors'] != null) ...[
          const SizedBox(height: 8),
          Text('Failed numbers: ${(result['errors'] as List).join(', ')}',
              style: const TextStyle(fontSize: 11, color: AppTheme.danger)),
        ],
      ]),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ResultStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
    ]),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF25D366) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.textSecondary)),
    ),
  );
}

class _TargetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TargetChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppTheme.textSecondary)),
    ),
  );
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TemplateChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF128C7E))),
    ),
  );
}

// ── Notif Card ────────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationModel n;
  final VoidCallback onRead;
  const _NotifCard({required this.n, required this.onRead});

  Color get _dotColor {
    switch (n.type) {
      case 'FEE_REMINDER': return AppTheme.warning;
      case 'ANNOUNCEMENT': return AppTheme.accent;
      case 'COMPLAINT_UPDATE': return AppTheme.primary;
      default: return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onRead,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.isRead ? AppTheme.surface : AppTheme.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: n.isRead ? AppTheme.border : AppTheme.primary.withOpacity(0.3), width: 0.5),
      ),
      child: Row(children: [
        Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: n.isRead ? AppTheme.border : _dotColor)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 3),
          Text(n.message, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          Text(n.createdAt.length > 10 ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(n.createdAt)) : n.createdAt,
              style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
        ])),
      ]),
    ),
  );
}