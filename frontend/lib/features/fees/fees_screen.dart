import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/fees_provider.dart';
import '../../core/models/fee_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

// ── Fee Summary Provider ──────────────────────────────────────────────────────
final feeSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient().get('/fees/summary');
  return res.data as Map<String, dynamic>;
});

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});
  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Fee Management'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Monthly'),
            Tab(text: 'Pending'),
            Tab(text: 'History'),
          ],
        ),
        actions: const [],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _SummaryTab(isAdmin: isAdmin),
          _MonthlyTab(isAdmin: isAdmin),
          _PendingTab(isAdmin: isAdmin),
          _HistoryTab(),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showFeesActions(context),
              child: const Icon(Icons.add_task),
            )
          : null,
    );
  }

  void _showFeesActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Administrative Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
              title: const Text('Generate Monthly Fees'),
              onTap: () {
                Navigator.pop(ctx);
                _showGenerateDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppTheme.warning),
              title: const Text('Increment Fees (Yearly)'),
              onTap: () {
                Navigator.pop(ctx);
                _showIncrementDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined, color: AppTheme.danger),
              title: const Text('Mark Overdue'),
              onTap: () {
                Navigator.pop(ctx);
                _markOverdue(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment_outlined, color: AppTheme.accent),
              title: const Text('Record Manual Payment'),
              onTap: () {
                Navigator.pop(ctx);
                _showManualPaymentDialog(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    int month = DateTime.now().month;
    int year  = DateTime.now().year;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Generate Monthly Fees'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            initialValue: month,
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
            onChanged: (v) => setSt(() => month = v!),
            decoration: const InputDecoration(labelText: 'Month'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: year.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Year'),
            onChanged: (v) => year = int.tryParse(v) ?? year,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            Navigator.of(ctx).pop();
            try {
              final res = await ApiClient().post('/fees/generate', data: {'month': month, 'year': year});
              ref.invalidate(feeSummaryProvider);
              ref.invalidate(currentMonthFeesProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res.data['message'] ?? 'Fees generated'), backgroundColor: AppTheme.primary));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
              }
            }
          }, child: const Text('Generate')),
        ],
      )),
    );
  }

  void _showIncrementDialog(BuildContext context) {
    final pctCtrl = TextEditingController();
    int month = DateTime.now().month;
    int year  = DateTime.now().year;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Increment Fees'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
              SizedBox(width: 8),
              Expanded(child: Text('Updates monthly rent for ALL active tenants', style: TextStyle(fontSize: 12, color: AppTheme.warning))),
            ]),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: pctCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Increment %', hintText: 'e.g. 10 for 10%', prefixIcon: Icon(Icons.percent)),
          ),
          const SizedBox(height: 12),
          const Text('Effective From', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              initialValue: month,
              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
              onChanged: (v) => setSt(() => month = v!),
              decoration: const InputDecoration(labelText: 'Month'),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              initialValue: year.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year'),
              onChanged: (v) => year = int.tryParse(v) ?? year,
            )),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () async {
              final pct = double.tryParse(pctCtrl.text);
              if (pct == null || pct <= 0) return;
              Navigator.of(ctx).pop();
              try {
                final res = await ApiClient().post('/fees/increment', data: {
                  'percentage': pct, 'effectiveMonth': month, 'effectiveYear': year,
                });
                ref.invalidate(feeSummaryProvider);
                if (context.mounted) showDialog(context: context, builder: (_) => _IncrementResultDialog(data: res.data));
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                }
              }
            },
            child: const Text('Apply Increment', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Future<void> _markOverdue(BuildContext context) async {
    try {
      final res = await ApiClient().post('/fees/mark-overdue', data: {});
      ref.invalidate(feeSummaryProvider);
      ref.invalidate(pendingFeesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res.data['updated']} fees marked overdue'), backgroundColor: AppTheme.warning));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _showManualPaymentDialog(BuildContext context) async {
    // We need to fetch students first. For simplicity, we'll fetch from API directly here
    // or use a dedicated dialog.
    showDialog(
      context: context,
      builder: (ctx) => _ManualPaymentDialog(onSuccess: () {
        ref.invalidate(feeSummaryProvider);
        ref.invalidate(currentMonthFeesProvider);
        ref.invalidate(pendingFeesProvider);
      }),
    );
  }
}

class _ManualPaymentDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _ManualPaymentDialog({required this.onSuccess});
  @override
  ConsumerState<_ManualPaymentDialog> createState() => _ManualPaymentDialogState();
}

class _ManualPaymentDialogState extends ConsumerState<_ManualPaymentDialog> {
  String? _selectedStudentId;
  String? _studentName;
  String? _roomDetails;
  String? _mode = 'Cash';
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _loading = false;
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final res = await ApiClient().get('/students');
      setState(() {
        _students = res.data;
        _filteredStudents = res.data;
      });
    } catch (_) {}
  }

  void _filter(String q) {
    setState(() {
      _filteredStudents = _students.where((s) => 
        (s['name'] as String).toLowerCase().contains(q.toLowerCase()) ||
        (s['mobile'] as String).contains(q)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return AlertDialog(
      title: const Text('Record Manual Payment'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_selectedStudentId == null) ...[
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(labelText: 'Search Tenant', prefixIcon: Icon(Icons.search)),
              onChanged: _filter,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: _students.isEmpty 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (ctx, i) {
                      final s = _filteredStudents[i];
                      return ListTile(
                        dense: true,
                        title: Text(s['name']),
                        subtitle: Text('Room ${s['room']?['roomNumber'] ?? ''}'),
                        onTap: () => setState(() {
                          _selectedStudentId = s['id'];
                          _studentName = s['name'];
                          _roomDetails = 'Room ${s['room']?['roomNumber'] ?? ''}';
                        }),
                      );
                    },
                  ),
            ),
          ] else ...[
            ListTile(
              dense: true,
              title: Text(_studentName!),
              subtitle: Text(_roomDetails!),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedStudentId = null)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<int>(
                value: _month,
                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
                onChanged: (v) => setState(() => _month = v!),
                decoration: const InputDecoration(labelText: 'Month'),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                initialValue: _year.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
                onChanged: (v) => _year = int.tryParse(v) ?? _year,
              )),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mode,
              items: ['Cash','UPI','Bank Transfer','Cheque']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _mode = v),
              decoration: const InputDecoration(labelText: 'Payment Mode'),
            ),
          ],
        ]),
      ),
      actions: [
        if (_selectedStudentId != null)
        ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            try {
              await ApiClient().post('/fees/payment', data: {
                'studentId': _selectedStudentId,
                'month': _month,
                'year': _year,
                'paymentMode': _mode,
              });
              widget.onSuccess();
              if (mounted) Navigator.pop(context);
            } catch (e) {
              setState(() => _loading = false);
            }
          },
          child: _loading ? const CircularProgressIndicator() : const Text('Confirm'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY TAB — Today / Monthly / Yearly / Dues
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryTab extends ConsumerWidget {
  final bool isAdmin;
  const _SummaryTab({required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,###');
    final summaryAsync = ref.watch(feeSummaryProvider);

    return summaryAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorWidget2(
          message: 'Failed to load summary',
          onRetry: () => ref.invalidate(feeSummaryProvider)),
      data: (data) {
        final today   = data['today']   as Map<String, dynamic>;
        final monthly = data['monthly'] as Map<String, dynamic>;
        final yearly  = data['yearly']  as Map<String, dynamic>;
        final overdue = data['overdue'] as Map<String, dynamic>;
        final deposits = data['deposits'] as Map<String, dynamic>;

        final monthNames = ['', 'Jan','Feb','Mar','Apr','May','Jun',
                                'Jul','Aug','Sep','Oct','Nov','Dec'];
        final currentMonth = monthNames[monthly['month'] as int];

        return RefreshIndicator(
          onRefresh: () => ref.refresh(feeSummaryProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── TODAY ────────────────────────────────────────────
              _PeriodHeader(icon: Icons.today_outlined, label: "Today's Collection",
                  date: DateFormat('dd MMM yyyy').format(DateTime.now())),
              const SizedBox(height: 8),
              _BigStatCard(
                value: '₹${fmt.format((today['revenue'] as num).toInt())}',
                label: '${today['count']} payment(s) received today',
                color: AppTheme.primary,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(height: 20),

              // ── MONTHLY ──────────────────────────────────────────
              _PeriodHeader(icon: Icons.calendar_month_outlined,
                  label: '$currentMonth ${monthly['year']} — Monthly'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _StatCard(
                  label: 'Collected',
                  value: '₹${fmt.format((monthly['revenue'] as num).toInt())}',
                  sub: '${monthly['paidCount']} tenants',
                  color: AppTheme.primary,
                  icon: Icons.check_circle_outline,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  label: 'Pending',
                  value: '₹${fmt.format((monthly['pending'] as num).toInt())}',
                  sub: '${monthly['pendingCount']} tenants',
                  color: AppTheme.warning,
                  icon: Icons.schedule_outlined,
                )),
              ]),
              const SizedBox(height: 8),
              // Progress bar
              _CollectionProgress(
                collected: (monthly['paidCount'] as int),
                total: (monthly['total'] as int),
              ),
              const SizedBox(height: 20),

              // ── YEARLY ───────────────────────────────────────────
              _PeriodHeader(icon: Icons.bar_chart_outlined,
                  label: '${yearly['year']} — Annual Overview'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _StatCard(
                  label: 'Total Collected',
                  value: '₹${fmt.format((yearly['revenue'] as num).toInt())}',
                  sub: '${yearly['paidCount']} payments',
                  color: AppTheme.accent,
                  icon: Icons.trending_up_outlined,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  label: 'Yet to Collect',
                  value: '₹${fmt.format((yearly['pending'] as num).toInt())}',
                  sub: '${yearly['pendingCount']} pending',
                  color: AppTheme.textSecondary,
                  icon: Icons.pending_outlined,
                )),
              ]),
              const SizedBox(height: 20),

              // ── OVERDUE / DUES ────────────────────────────────────
              const _PeriodHeader(icon: Icons.warning_amber_outlined,
                  label: 'Overdue Dues', color: AppTheme.danger),
              const SizedBox(height: 8),
              if ((overdue['count'] as int) == 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Text('No overdue dues — all clear!',
                        style: TextStyle(fontSize: 13, color: AppTheme.primaryDark, fontWeight: FontWeight.w500)),
                  ]),
                )
              else ...[
                _BigStatCard(
                  value: '₹${fmt.format((overdue['amount'] as num).toInt())}',
                  label: '${overdue['count']} tenants with overdue payments',
                  color: AppTheme.danger,
                  icon: Icons.warning_amber_rounded,
                ),
                const SizedBox(height: 10),
                // Overdue student list
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: (overdue['fees'] as List).map((f) {
                      final student = f['student'] as Map<String, dynamic>?;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(student?['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('Room ${student?['room']?['roomNumber'] ?? ''}  •  ${student?['mobile'] ?? ''}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                          ])),
                          Text('₹${fmt.format((f['amount'] as num).toInt())}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.danger)),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── DEPOSITS ─────────────────────────────────────────
              const _PeriodHeader(icon: Icons.savings_outlined, label: 'Security Deposits Held'),
              const SizedBox(height: 8),
              _BigStatCard(
                value: '₹${fmt.format((deposits['total'] as num).toInt())}',
                label: 'From ${deposits['count']} active tenants',
                color: AppTheme.primaryDark,
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
            ]),
          ),
        );
      },
    );
  }
}

// ── Monthly Tab ───────────────────────────────────────────────────────────────
class _MonthlyTab extends ConsumerWidget {
  final bool isAdmin;
  const _MonthlyTab({required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,###');
    final filters = ref.watch(monthlyFiltersProvider);
    final async = ref.watch(currentMonthFeesProvider);

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 2 + i);

    return Column(
      children: [
        // ── FILTERS ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: filters['month'],
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(months[i], style: const TextStyle(fontSize: 13)),
                  )),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(monthlyFiltersProvider.notifier).update((s) => {...s, 'month': v});
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Month',
                    isDense: true,
                    prefixIcon: const Icon(Icons.calendar_month, size: 16, color: AppTheme.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: filters['year'],
                  items: years.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y.toString(), style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(monthlyFiltersProvider.notifier).update((s) => {...s, 'year': v});
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Year',
                    isDense: true,
                    prefixIcon: const Icon(Icons.event_note, size: 16, color: AppTheme.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: async.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorWidget2(message: 'Failed to load', onRetry: () => ref.invalidate(currentMonthFeesProvider)),
            data: (data) {
              final summary = data['summary'] as Map<String, dynamic>;
              final fees = (data['fees'] as List).map((e) => FeeModel.fromJson(e)).toList();
              final selectedDate = DateTime(filters['year']!, filters['month']!);
              
              return RefreshIndicator(
                onRefresh: () => ref.refresh(currentMonthFeesProvider.future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: MetricCard(
                          label: 'Collected', icon: Icons.check_circle_outline,
                          value: '₹${fmt.format((summary['collectedAmount'] ?? 0).toInt())}',
                          valueColor: AppTheme.primary,
                          subtitle: '${summary['paid']} tenants')),
                      const SizedBox(width: 10),
                      Expanded(child: MetricCard(
                          label: 'Pending', icon: Icons.schedule_outlined,
                          value: '₹${fmt.format((summary['pendingAmount'] ?? 0).toInt())}',
                          valueColor: AppTheme.danger,
                          subtitle: '${summary['pending']} tenants')),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border, width: 0.5),
                      ),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(children: [
                            Text(DateFormat('MMMM yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${fees.length} tenants',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                          ]),
                        ),
                        const AppDivider(),
                        if (fees.isEmpty)
                          const Padding(padding: EdgeInsets.all(24),
                              child: EmptyState(message: 'No fees generated yet'))
                        else
                          ...fees.map((f) => _FeeRow(
                              fee: f, isAdmin: isAdmin,
                              onPaid: () => _recordPayment(context, ref, f))),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref, FeeModel fee) async {
    String? mode = 'Cash';
    int month = fee.month;
    int year = fee.year;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(dense: true,
              title: Text(fee.student?.name ?? ''),
              subtitle: Text('Room ${fee.student?.room?.roomNumber ?? ''}')),
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
                  'studentId': fee.studentId, 'month': month,
                  'year': year, 'paymentMode': mode,
                });
                ref.invalidate(currentMonthFeesProvider);
                ref.invalidate(feeSummaryProvider);
                ref.invalidate(pendingFeesProvider);
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
}

// ── Pending Tab ───────────────────────────────────────────────────────────────
class _PendingTab extends ConsumerWidget {
  final bool isAdmin;
  const _PendingTab({required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,###');
    return ref.watch(pendingFeesProvider).when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorWidget2(message: 'Failed to load', onRetry: () => ref.invalidate(pendingFeesProvider)),
      data: (fees) => fees.isEmpty
          ? const EmptyState(message: 'No pending payments!',
              icon: Icons.check_circle_outline, subtitle: 'All fees collected')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: fees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final f = fees[i];
                final isOverdue = f.status == 'OVERDUE';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOverdue ? AppTheme.danger.withOpacity(0.4) : AppTheme.border,
                      width: 0.5,
                    ),
                  ),
                  child: Row(children: [
                    AvatarCircle(name: f.student?.name ?? '?',
                        bgColor: isOverdue ? AppTheme.dangerLight : null),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.student?.name ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('Room ${f.student?.room?.roomNumber ?? ''} • ${f.monthName} ${f.year}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₹${fmt.format(f.amount.toInt())}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: isOverdue ? AppTheme.danger : AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      StatusBadge(status: f.status),
                    ]),
                  ]),
                );
              }),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,###');
    final filters = ref.watch(historyFiltersProvider);
    final historyAsync = ref.watch(historyFeesProvider);

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 2 + i);

    return Column(
      children: [
        // ── FILTERS ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: filters['month'],
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(months[i], style: const TextStyle(fontSize: 13)),
                  )),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(historyFiltersProvider.notifier).update((s) => {...s, 'month': v});
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Month',
                    isDense: true,
                    prefixIcon: const Icon(Icons.calendar_month, size: 16, color: AppTheme.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: filters['year'],
                  items: years.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y.toString(), style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(historyFiltersProvider.notifier).update((s) => {...s, 'year': v});
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Year',
                    isDense: true,
                    prefixIcon: const Icon(Icons.event_note, size: 16, color: AppTheme.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── HISTORY LIST ─────────────────────────────────────────────────────
        Expanded(
          child: historyAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorWidget2(
              message: 'Failed to load history',
              onRetry: () => ref.invalidate(historyFeesProvider),
            ),
            data: (data) {
              final paid = (data['fees'] as List)
                  .map((e) => FeeModel.fromJson(e))
                  .where((f) => f.status == 'PAID')
                  .toList();

              return RefreshIndicator(
                onRefresh: () => ref.refresh(historyFeesProvider.future),
                child: paid.isEmpty
                    ? const EmptyState(message: 'No payment history for this period', icon: Icons.history)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: paid.length,
                        separatorBuilder: (_, __) => const AppDivider(),
                        itemBuilder: (_, i) {
                          final f = paid[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(children: [
                              const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f.student?.name ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text(
                                  'For ${f.monthName} ${f.year}  •  Paid on ${f.paidDate != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(f.paidDate!)) : DateFormat('dd MMM yyyy').format(DateTime.now())}  •  ${f.paymentMode ?? 'Cash'}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                                ),
                              ])),
                              Text('₹${fmt.format(f.amount.toInt())}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                            ]),
                          );
                        }),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? date;
  final Color color;
  const _PeriodHeader({required this.icon, required this.label, this.date, this.color = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: color),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    if (date != null) ...[
      const Spacer(),
      Text(date!, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
    ],
  ]);
}

class _BigStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _BigStatCard({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.sub, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
    ]),
  );
}

class _CollectionProgress extends StatelessWidget {
  final int collected;
  final int total;
  const _CollectionProgress({required this.collected, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? collected / total : 0.0;
    final pct = (ratio * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Collection Rate', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text('$collected / $total tenants ($pct%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: AppTheme.border,
            color: ratio >= 0.8 ? AppTheme.primary : ratio >= 0.5 ? AppTheme.warning : AppTheme.danger,
            minHeight: 8,
          ),
        ),
      ]),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final FeeModel fee;
  final bool isAdmin;
  final VoidCallback onPaid;
  const _FeeRow({required this.fee, required this.isAdmin, required this.onPaid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        AvatarCircle(name: fee.student?.name ?? '?', size: 34),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fee.student?.name ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text('Room ${fee.student?.room?.roomNumber ?? ''}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${fee.amount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          fee.status == 'PAID'
              ? const StatusBadge(status: 'PAID')
              : isAdmin
                  ? GestureDetector(
                      onTap: onPaid,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Mark Paid', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                      ))
                  : StatusBadge(status: fee.status),
        ]),
      ]),
    );
  }
}

// ── Increment Result Dialog ───────────────────────────────────────────────────
class _IncrementResultDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  const _IncrementResultDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    final students = (data['students'] as List?) ?? [];
    return AlertDialog(
      title: const Text('Fee Increment Applied'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['message'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
              Text('From: ${data['effectiveFrom']}', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Updated students:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 12))),
                    Text('₹${s['oldRent']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, decoration: TextDecoration.lineThrough)),
                    const Icon(Icons.arrow_forward, size: 14, color: AppTheme.textTertiary),
                    Text('₹${s['newRent']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
      ],
    );
  }
}