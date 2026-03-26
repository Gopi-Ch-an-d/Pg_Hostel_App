import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/students_provider.dart';
import '../../core/models/student_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});
  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isAdmin ?? false;
    final canManage = isAdmin || (user?.role == 'SUPERVISOR');
    final filter = ref.watch(studentsFilterProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,

      // ── AppBar — no add icon ─────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Tenants'),
        // ✅ actions removed — add button moved to FAB below
      ),

      // ✅ Floating Action Button — icon only
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => context
                  .push('/students/add')
                  .then((_) => ref.invalidate(studentsProvider)),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              tooltip: 'Add Tenant',
              child: const Icon(Icons.person_add_outlined, size: 22),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Column(children: [
        // ── Search + filter bar ───────────────────────────────
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(children: [
            SearchField(
              controller: _searchCtrl,
              hint: 'Search name, mobile, room...',
              onChanged: (v) => ref
                  .read(studentsFilterProvider.notifier)
                  .state = filter.copyWith(search: v),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: FilterChips(
                options: const ['paid', 'pending'],
                selected: filter.status,
                onChanged: (v) => ref
                    .read(studentsFilterProvider.notifier)
                    .state = filter.copyWith(status: v),
              )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: DropdownButton<String?>(
                  value: filter.floor,
                  hint: const Text('Floor',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  underline: const SizedBox(),
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: AppTheme.textSecondary),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Floors')),
                    ...['1', '2', '3', '4', '5', '6', '7', '8'].map((f) =>
                        DropdownMenuItem(value: f, child: Text('Floor $f'))),
                  ],
                  onChanged: (v) => ref
                      .read(studentsFilterProvider.notifier)
                      .state = filter.copyWith(floor: v),
                ),
              ),
            ]),
          ]),
        ),
        const AppDivider(),

        // ── Summary bar ───────────────────────────────────────
        studentsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (students) {
            final total = students.length;
            final paid = students.where((s) => s.latestFeeStatus == 'PAID').length;
            final pending = students.where((s) => s.latestFeeStatus != 'PAID').length;
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(children: [
                _SummaryBadge(label: 'Total', value: '$total', color: AppTheme.accent),
                const SizedBox(width: 10),
                _SummaryBadge(label: 'Paid', value: '$paid', color: AppTheme.primary),
                const SizedBox(width: 10),
                _SummaryBadge(label: 'Pending', value: '$pending', color: AppTheme.danger),
              ]),
            );
          },
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        Expanded(
            child: studentsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorWidget2(
              message: 'Failed to load tenants',
              onRetry: () => ref.invalidate(studentsProvider)),
          data: (students) => students.isEmpty
              ? EmptyState(
                  message: 'No tenants found',
                  icon: Icons.people_outline,
                  onAction: canManage ? () => context.push('/students/add') : null,
                  actionLabel: 'Add Tenant',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(studentsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // ✅ bottom pad so FAB doesn't cover last card
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _StudentTile(
                      student: students[i],
                      isAdmin: isAdmin,
                      canManage: canManage,
                      onTap: () => context
                          .push('/students/${students[i].id}')
                          .then((_) => ref.invalidate(studentsProvider)),
                      onPay: _payFee,
                      onDelete: isAdmin
                          ? () => _confirmDelete(context, ref, students[i])
                          : null,
                      onVacateNotice: canManage
                          ? () => _showVacateNoticeDialog(context, students[i])
                          : null,
                    ),
                  ),
                ),
        )),
      ]),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remove ${student.name} from the system?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.dangerLight,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text(
                    'This will free up their bed and mark them inactive.',
                    style: TextStyle(fontSize: 12, color: AppTheme.danger)),
              ),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiClient().delete('/students/${student.id}');
        ref.invalidate(studentsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Student removed'),
              backgroundColor: AppTheme.primary));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger));
        }
      }
    }
  }

  void _showVacateNoticeDialog(BuildContext context, StudentModel student) {
    DateTime vacateDate = DateTime.now().add(const Duration(days: 15));
    final reasonCtrl = TextEditingController();
    final fmt = DateFormat('dd MMMM yyyy');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.exit_to_app_outlined,
                  color: AppTheme.warning, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('Send Vacate Notice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      AvatarCircle(name: student.name, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(student.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                                'Room ${student.room?.roomNumber ?? ''} • ${student.mobile}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textSecondary)),
                          ])),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text('Vacate By Date',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: vacateDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (d != null) setSt(() => vacateDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppTheme.warning),
                        const SizedBox(width: 10),
                        Text(fmt.format(vacateDate),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.warning)),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.warning),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Quick Select',
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _NoticePill('7 days', 7, vacateDate,
                        (d) => setSt(() => vacateDate = d)),
                    _NoticePill('15 days', 15, vacateDate,
                        (d) => setSt(() => vacateDate = d)),
                    _NoticePill('1 month', 30, vacateDate,
                        (d) => setSt(() => vacateDate = d)),
                    _NoticePill('Immediate', 0, vacateDate,
                        (d) => setSt(() => vacateDate = d)),
                  ]),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'e.g. Student requested to vacate',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Text('📱', style: TextStyle(fontSize: 16)),
              label: const Text('Send Notice',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final msg = _buildVacateMessage(
                      student.name,
                      student.room?.roomNumber ?? '',
                      vacateDate,
                      reasonCtrl.text);
                  final res = await ApiClient().post(
                    '/notifications/whatsapp/student/${student.id}',
                    data: {'message': msg},
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res.data['success'] == true
                          ? '✅ Vacate notice sent to ${student.name}!'
                          : '❌ Failed: ${res.data['error']}'),
                      backgroundColor: res.data['success'] == true
                          ? AppTheme.primary
                          : AppTheme.danger,
                      duration: const Duration(seconds: 3),
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.danger));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payFee(BuildContext context, WidgetRef ref, StudentModel student) async {
    String? mode = 'Cash';
    int month = DateTime.now().month;
    int year = DateTime.now().year;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(dense: true,
              title: Text(student.name),
              subtitle: Text('Room ${student.room?.roomNumber ?? ''}')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: month,
              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
              onChanged: (v) => setSt(() => month = v!),
              decoration: const InputDecoration(labelText: 'Month'),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(
              initialValue: year.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year'),
              onChanged: (v) => year = int.tryParse(v) ?? year,
            )),
          ]),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: mode,
            items: ['Cash','UPI','Bank Transfer','Cheque']
                .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setSt(() => mode = v),
            decoration: const InputDecoration(labelText: 'Payment Mode'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ApiClient().post('/fees/payment', data: {
                  'studentId': student.id, 'month': month,
                  'year': year, 'paymentMode': mode,
                });
                ref.invalidate(studentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment recorded!'), backgroundColor: AppTheme.primary));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                }
              }
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      )),
    );
  }

  String _buildVacateMessage(
      String name, String roomNumber, DateTime vacateDate, String reason) {
    final fmt = DateFormat('dd MMMM yyyy');
    final today = fmt.format(DateTime.now());
    final vacateDateStr = fmt.format(vacateDate);
    final isImmediate = vacateDate.difference(DateTime.now()).inDays <= 1;
    return '''🏠 *PG Hostel — Vacate Notice*

Dear *$name*,

${isImmediate ? 'As per your request, you are required to vacate *immediately*.' : 'This is to inform you that you are required to vacate your room by *$vacateDateStr*.'}

📋 *Details:*
• Room Number: *$roomNumber*
• Notice Date: *$today*
• Vacate By: *$vacateDateStr*
${reason.isNotEmpty ? '• Reason: $reason' : ''}

📌 *Before Vacating Please:*
• Clear all pending dues
• Return room keys to management
• Collect your security deposit

Thank you for staying with us! 🙏
— *PG Management* 🏠''';
  }
}

// ── Summary Badge ─────────────────────────────────────────────────────────────
class _SummaryBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 0.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

// ── Notice Pill ───────────────────────────────────────────────────────────────
class _NoticePill extends StatelessWidget {
  final String label;
  final int days;
  final DateTime current;
  final ValueChanged<DateTime> onSelected;
  const _NoticePill(this.label, this.days, this.current, this.onSelected);

  @override
  Widget build(BuildContext context) {
    final target =
        days == 0 ? DateTime.now() : DateTime.now().add(Duration(days: days));
    final isSelected = DateFormat('dd-MM-yyyy').format(current) ==
        DateFormat('dd-MM-yyyy').format(target);
    return GestureDetector(
      onTap: () => onSelected(target),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.warning : AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.warning : AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}

// ── Student Tile ──────────────────────────────────────────────────────────────
class _StudentTile extends ConsumerWidget {
  final StudentModel student;
  final bool isAdmin, canManage;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onVacateNotice;
  final Function(BuildContext, WidgetRef, StudentModel) onPay;

  const _StudentTile({
    required this.student,
    required this.isAdmin,
    required this.canManage,
    required this.onTap,
    required this.onPay,
    this.onDelete,
    this.onVacateNotice,
  });

  Future<void> _openWhatsApp(BuildContext context) async {
    final phone = student.mobile.replaceAll(RegExp(r'\D'), '');
    final number = phone.startsWith('91') ? phone : '91$phone';
    final waUrl = Uri.parse('https://wa.me/$number');
    final waScheme = Uri.parse('whatsapp://send?phone=$number');
    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(waScheme)) {
        await launchUrl(waScheme, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse('https://play.google.com/store/apps/details?id=com.whatsapp'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: AppTheme.danger));
      }
    }
  }

  Future<void> _callStudent(BuildContext context) async {
    final uri = Uri.parse('tel:${student.mobile}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Could not open dialer'),
              backgroundColor: AppTheme.danger));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(children: [
              AvatarCircle(name: student.name),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(student.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(student.mobile,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE6F1FB),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('Room ${student.room?.roomNumber ?? ''}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0C447C),
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      Text('Floor ${student.room?.floor ?? ''}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textTertiary)),
                    ]),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                StatusBadge(status: student.latestFeeStatus),
                const SizedBox(height: 4),
                Text('₹${student.monthlyRent.toInt()}/mo',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
              ]),
            ]),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            
            Row(children: [
              _IconOnlyButton(
                faIcon: FontAwesomeIcons.whatsapp,
                color: const Color(0xFF25D366),
                tooltip: 'WhatsApp',
                onTap: () => _openWhatsApp(context),
              ),
              const SizedBox(width: 8),
              _IconOnlyButton(
                icon: Icons.call_rounded,
                color: AppTheme.primary,
                tooltip: 'Call',
                onTap: () => _callStudent(context),
              ),
              const Spacer(),
              if (canManage) ...[
                _SmallIconBtn(
                  icon: Icons.edit_outlined,
                  color: AppTheme.textTertiary,
                  onTap: onTap,
                ),
                const SizedBox(width: 8),
              ],
              if (isAdmin && onDelete != null)
                _SmallIconBtn(
                  icon: Icons.delete_outline,
                  color: AppTheme.danger,
                  onTap: onDelete!,
                ),
            ]),
            if (canManage) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.payments_outlined,
                    label: 'Pay',
                    color: AppTheme.primary,
                    onTap: () => onPay(context, ref, student),
                  ),
                ),
                if (onVacateNotice != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.exit_to_app_rounded,
                      label: 'Vacate',
                      color: AppTheme.warning,
                      onTap: onVacateNotice!,
                    ),
                  ),
                ],
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Icon-Only Button ──────────────────────────────────────────────────────────
class _IconOnlyButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final IconData? icon;
  final IconData? faIcon;

  const _IconOnlyButton({
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.icon,
    this.faIcon,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.25), width: 0.5),
            ),
            child: Center(
              child: faIcon != null
                  ? FaIcon(faIcon!, size: 18, color: color)
                  : Icon(icon!, size: 18, color: color),
            ),
          ),
        ),
      );
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25), width: 0.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
        ),
      );
}

// ── Small Icon Button ─────────────────────────────────────────────────────────
class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallIconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      this.tooltip});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Tooltip(
            message: tooltip ?? '', child: Icon(icon, size: 16, color: color)),
      );
}