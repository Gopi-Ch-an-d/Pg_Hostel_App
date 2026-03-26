import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/logo_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final dashAsync = ref.watch(dashboardProvider);
    final fmt = NumberFormat('#,##,###');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorWidget2(
              message: e.toString(),
              onRetry: () => ref.refresh(dashboardProvider.future)),
          data: (summary) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [
              // ── Modern Gradient Header ─────────────────────────────
              _PremiumHeader(auth: auth),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(children: [
                   // Offset Finance Card
                  Transform.translate(
                    offset: const Offset(0, -35),
                    child: _FinanceCard(summary: summary, fmt: fmt),
                  ),

                  // Quick Metrics
                  const _SectionHeader(title: 'Overview', icon: Icons.insights_rounded),
                  const SizedBox(height: 12),
                  _MetricsGrid(summary: summary),
                  const SizedBox(height: 24),

                  // Room Health
                  const _SectionHeader(title: 'Occupancy Health', icon: Icons.pie_chart_outline_rounded),
                  const SizedBox(height: 12),
                  _RoomOverviewCard(summary: summary),
                  const SizedBox(height: 24),

                  // Inventory Alert
                  if (summary.damagedInventory > 0) ...[
                    const _SectionHeader(title: 'Alerts', icon: Icons.notification_important_outlined),
                    const SizedBox(height: 12),
                    _InventoryAlert(summary: summary),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── New Premium Header ────────────────────────────────────────────────────────
class _PremiumHeader extends ConsumerWidget {
  final AuthState auth;
  const _PremiumHeader({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon,';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening,';
    } else {
      greeting = 'Good Night,';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 60,
        left: 20,
        right: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const AppLogo(size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PG HOSTEL',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              Text('Smart Management System',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ]),
        const SizedBox(height: 28),
        Text(greeting, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
        const SizedBox(height: 4),
        Text(auth.user?.name ?? 'Administrator',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.textSecondary),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
    ]);
  }
}

// ── Finance Card Redesign ─────────────────────────────────────────────────────
class _FinanceCard extends StatelessWidget {
  final DashboardSummary summary;
  final NumberFormat fmt;
  const _FinanceCard({required this.summary, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          _FinanceItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Today',
              value: '₹${fmt.format(summary.todayRevenue.toInt())}',
              subtitle: 'Revenue',
              color: const Color(0xFF6366F1)), // Indigo
          _vDivider(),
          _FinanceItem(
              icon: Icons.trending_up_rounded,
              label: 'Monthly',
              value: '₹${fmt.format(summary.monthlyRevenue.toInt())}',
              subtitle: '${summary.paidCount} Receipts',
              color: const Color(0xFF10B981)), // Emerald
          _vDivider(),
          _FinanceItem(
              icon: Icons.priority_high_rounded,
              label: 'Dues',
              value: '₹${fmt.format(summary.pendingAmount.toInt())}',
              subtitle: '${summary.pendingCount} Pending',
              color: const Color(0xFFEF4444), // Rose
              onTap: () => context.push('/fees')),
        ]),
      ),
    );
  }

  Widget _vDivider() => VerticalDivider(color: Colors.grey.withOpacity(0.15), width: 1, thickness: 1, indent: 20, endIndent: 20);
}

class _FinanceItem extends StatelessWidget {
  final IconData icon;
  final String label, value, subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _FinanceItem({required this.icon, required this.label, required this.value, required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textTertiary, letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }
}

// ── Metrics Grid ──────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final DashboardSummary summary;
  const _MetricsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.3, // Increased from 1.5 to fix overflow
      children: [
        _MetricCard(
          title: 'Total Tenants',
          value: '${summary.totalStudents}',
          icon: Icons.people_outline_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => context.push('/students'),
        ),
        _MetricCard(
          title: 'Total Rooms',
          value: '${summary.totalRooms}',
          subtitle: '${summary.occupiedRooms} Occupied',
          icon: Icons.other_houses_outlined,
          color: const Color(0xFF8B5CF6),
          onTap: () => context.push('/rooms'),
        ),
        _MetricCard(
          title: 'Vacant Beds',
          value: '${summary.vacantBeds}',
          icon: Icons.bed_outlined,
          color: summary.vacantBeds > 0 ? const Color(0xFF10B981) : Colors.red,
          onTap: () => context.push('/rooms'),
        ),
        _MetricCard(
          title: 'Complaints',
          value: '${summary.openComplaints}',
          icon: Icons.bolt_outlined,
          color: summary.openComplaints > 0 ? const Color(0xFFF59E0B) : Colors.blueGrey,
          onTap: () => context.push('/complaints'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MetricCard({required this.title, required this.value, this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, color: color, size: 22),
            Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey.withOpacity(0.4)),
          ]),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textTertiary)),
        ]),
      ),
    );
  }
}

// ── Room Overview ─────────────────────────────────────────────────────────────
class _RoomOverviewCard extends StatelessWidget {
  final DashboardSummary summary;
  const _RoomOverviewCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(children: [
        _ProgressRow(
            label: 'Occupied Rooms',
            count: summary.occupiedRooms,
            total: summary.totalRooms,
            color: const Color(0xFFEF4444)),
        const SizedBox(height: 14),
        _ProgressRow(
            label: 'Partially Filled',
            count: summary.totalRooms - summary.occupiedRooms - summary.availableRooms,
            total: summary.totalRooms,
            color: const Color(0xFFF59E0B)),
        const SizedBox(height: 14),
        _ProgressRow(
            label: 'Total Vacant',
            count: summary.availableRooms,
            total: summary.totalRooms,
            color: const Color(0xFF10B981)),
      ]),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _ProgressRow({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        Text('$count/$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: ratio,
          backgroundColor: color.withOpacity(0.1),
          color: color,
          minHeight: 7,
        ),
      ),
    ]);
  }
}

// ── Inventory Alert ───────────────────────────────────────────────────────────
class _InventoryAlert extends StatelessWidget {
  final DashboardSummary summary;
  const _InventoryAlert({required this.summary});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/inventory'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFFFFF7ED), Colors.white.withOpacity(0.5)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFED7AA), width: 1),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFF97316), size: 24),
          const SizedBox(width: 14),
          Expanded(child: Text('${summary.damagedInventory} items need repair', 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)))),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFF97316)),
        ]),
      ),
    );
  }
}
