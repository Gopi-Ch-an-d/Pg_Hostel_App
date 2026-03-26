import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/students/students_screen.dart';
import 'features/students/add_student_screen.dart';
import 'features/rooms/rooms_screen.dart' show RoomsScreen;
import 'features/fees/fees_screen.dart' show FeesScreen;
import 'features/complaints/complaints_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/mess/mess_screen.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: PgHostelApp()));
}

class PgHostelApp extends ConsumerWidget {
  const PgHostelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = auth.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        final isSplashing = state.matchedLocation == '/splash';

        if (isSplashing) return null; // Let the splash screen handle navigation
        if (!isLoggedIn && !isLoggingIn) return '/login';
        if (isLoggedIn && isLoggingIn) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen()),
            GoRoute(
                path: '/students', builder: (_, __) => const StudentsScreen()),
            GoRoute(
                path: '/students/add',
                builder: (_, __) => const AddStudentScreen()),
            GoRoute(
                path: '/students/:id',
                builder: (_, state) =>
                    AddStudentScreen(studentId: state.pathParameters['id'])),
            GoRoute(path: '/rooms', builder: (_, __) => const RoomsScreen()),
            GoRoute(path: '/fees', builder: (_, __) => const FeesScreen()),
            GoRoute(
                path: '/complaints',
                builder: (_, __) => const ComplaintsScreen()),
            GoRoute(
                path: '/notifications',
                builder: (_, __) => const NotificationsScreen()),
            GoRoute(
                path: '/inventory',
                builder: (_, __) => const InventoryScreen()),
            GoRoute(path: '/mess', builder: (_, __) => const MessScreen()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'PG Manager',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    // Determine active tab index
    int index = 0;
    if (location.startsWith('/students')) {
      index = 1;
    } else if (location.startsWith('/rooms'))
      index = 2;
    else if (location.startsWith('/fees'))
      index = 3;
    else if (location.startsWith('/complaints') ||
        location.startsWith('/notifications') ||
        location.startsWith('/inventory') ||
        location.startsWith('/mess')) index = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
          boxShadow: [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(children: [
              _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  index: 0,
                  current: index,
                  onTap: () => context.go('/dashboard')),
              _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  label: 'Tenants',
                  index: 1,
                  current: index,
                  onTap: () => context.go('/students')),
              _NavItem(
                  icon: Icons.meeting_room_outlined,
                  activeIcon: Icons.meeting_room_rounded,
                  label: 'Rooms',
                  index: 2,
                  current: index,
                  onTap: () => context.go('/rooms')),
              _NavItem(
                  icon: Icons.payment_outlined,
                  activeIcon: Icons.payment_rounded,
                  label: 'Fees',
                  index: 3,
                  current: index,
                  onTap: () => context.go('/fees')),
              _NavItem(
                  icon: Icons.more_horiz_outlined,
                  activeIcon: Icons.more_horiz_rounded,
                  label: 'More',
                  index: 4,
                  current: index,
                  onTap: () => _showMoreSheet(context)),
            ]),
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('More Options',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E))),
                ),
              ),
              _SheetTile(
                  icon: Icons.report_problem_outlined,
                  label: 'Complaints',
                  color: AppTheme.warning,
                  route: '/complaints',
                  context: context),
              _SheetTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  color: AppTheme.primary,
                  route: '/notifications',
                  context: context),
              _SheetTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  color: AppTheme.primaryDark,
                  route: '/inventory',
                  context: context),
              _SheetTile(
                  icon: Icons.restaurant_outlined,
                  label: 'Mess & Food',
                  color: const Color(0xFFE65100),
                  route: '/mess',
                  context: context),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav Item ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? AppTheme.primary : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── More Sheet Tile ───────────────────────────────────────────────────────────
class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final BuildContext context;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return ListTile(
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBBBBBB)),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
