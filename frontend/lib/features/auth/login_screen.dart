import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/logo_widget.dart';
import '../../core/services/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  int _selectedRole = 0;
  final _biometricService = BiometricService();
  bool _canCheckBiometrics = false;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _headerCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _field1Ctrl;
  late final AnimationController _field2Ctrl;
  late final AnimationController _btnCtrl;
  late final AnimationController _roleCtrl;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _field1Fade;
  late final Animation<Offset> _field1Slide;
  late final Animation<double> _field2Fade;
  late final Animation<Offset> _field2Slide;
  late final Animation<double> _btnFade;
  late final Animation<double> _btnScale;
  late final Animation<double> _roleFade;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedRole = _tabController.index;
          _userCtrl.clear();
          _passCtrl.clear();
        });
        _animateRoleSwitch();
      }
    });
    _setupAnimations();
    _runEntrance();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isAvailable();
    if (mounted) setState(() => _canCheckBiometrics = available);
  }

  void _setupAnimations() {
    // Header
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _headerSlide =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)
            .drive(Tween(
                begin: const Offset(0, -0.15), end: Offset.zero));

    // Card
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _cardSlide = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.08), end: Offset.zero));

    // Field 1
    _field1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _field1Fade = CurvedAnimation(parent: _field1Ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _field1Slide =
        CurvedAnimation(parent: _field1Ctrl, curve: Curves.easeOutCubic)
            .drive(Tween(
                begin: const Offset(0.08, 0), end: Offset.zero));

    // Field 2
    _field2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _field2Fade = CurvedAnimation(parent: _field2Ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _field2Slide =
        CurvedAnimation(parent: _field2Ctrl, curve: Curves.easeOutCubic)
            .drive(Tween(
                begin: const Offset(0.08, 0), end: Offset.zero));

    // Button
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _btnScale = CurvedAnimation(parent: _btnCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));

    // Role switcher
    _roleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _roleFade = CurvedAnimation(parent: _roleCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  Future<void> _runEntrance() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 180));
    _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 160));
    _field1Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _field2Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _btnCtrl.forward();
    _roleCtrl.forward();
  }

  Future<void> _animateRoleSwitch() async {
    // Re-run field animations on role switch
    _field1Ctrl.reset();
    _field2Ctrl.reset();
    _btnCtrl.reset();
    await Future.delayed(const Duration(milliseconds: 50));
    _field1Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _field2Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _headerCtrl.dispose();
    _cardCtrl.dispose();
    _field1Ctrl.dispose();
    _field2Ctrl.dispose();
    _btnCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _shakeCard();
      return;
    }
    final success = await ref
        .read(authProvider.notifier)
        .login(_userCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) {
      if (_canCheckBiometrics) {
        final authenticated = await _biometricService.authenticate();
        if (authenticated && mounted) {
          context.go('/dashboard');
        } else if (mounted) {
          // If biometric fails or is cancelled, stay on login and show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication failed')),
          );
        }
      } else {
        context.go('/dashboard');
      }
    }
  }

  Future<void> _shakeCard() async {
    for (int i = 0; i < 3; i++) {
      await _cardCtrl
          .animateTo(0.95, duration: const Duration(milliseconds: 60));
      await _cardCtrl
          .animateTo(1.0, duration: const Duration(milliseconds: 60));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Column(children: [
            // ── Animated Header ──────────────────────────────────────────────
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 60,
                    left: 24,
                    right: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(children: [
                    // ── Logo with glow ───────────────────────────────────────
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) => Transform.scale(
                        scale: v,
                        child: child,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const AppLogo(size: 60),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Title ────────────────────────────────────────────────
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (_, v, child) =>
                          Opacity(opacity: v, child: child),
                      child: const Text(
                        'PG Hostel',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (_, v, child) =>
                          Opacity(opacity: v, child: child),
                      child: Text(
                        'Hostel Management System',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Role selector ────────────────────────────────────────
                    FadeTransition(
                      opacity: _roleFade,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          _RolePill(
                            label: 'Admin',
                            icon: Icons.admin_panel_settings_rounded,
                            selected: _selectedRole == 0,
                            onTap: () {
                              _tabController.animateTo(0);
                              setState(() {
                                _selectedRole = 0;
                                _userCtrl.clear();
                                _passCtrl.clear();
                              });
                              _animateRoleSwitch();
                            },
                          ),
                          _RolePill(
                            label: 'Supervisor',
                            icon: Icons.manage_accounts_rounded,
                            selected: _selectedRole == 1,
                            onTap: () {
                              _tabController.animateTo(1);
                              setState(() {
                                _selectedRole = 1;
                                _userCtrl.clear();
                                _passCtrl.clear();
                              });
                              _animateRoleSwitch();
                            },
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Animated Card ────────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -32),
              child: FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppTheme.border, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Heading ─────────────────────────────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0, 0.3),
                                        end: Offset.zero)
                                    .animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              _selectedRole == 0
                                  ? 'Admin Sign In'
                                  : 'Supervisor Sign In',
                              key: ValueKey(_selectedRole),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter your credentials to continue',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Username field (slide from right) ───────────────
                          FadeTransition(
                            opacity: _field1Fade,
                            child: SlideTransition(
                              position: _field1Slide,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const _InputLabel(label: 'Username'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _userCtrl,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500),
                                      decoration: _inputDecoration(
                                        hint: _selectedRole == 0
                                            ? 'Enter admin username'
                                            : 'Enter supervisor username',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Password field (slide from right, delayed) ───────
                          FadeTransition(
                            opacity: _field2Fade,
                            child: SlideTransition(
                              position: _field2Slide,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const _InputLabel(label: 'Password'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passCtrl,
                                      obscureText: _obscure,
                                      onFieldSubmitted: (_) => _login(),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500),
                                      decoration: _inputDecoration(
                                        hint: 'Enter your password',
                                        icon: Icons.lock_outline_rounded,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: AppTheme.textTertiary,
                                          ),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure),
                                        ),
                                      ),
                                    ),
                                  ]),
                            ),
                          ),

                          // ── Error banner ─────────────────────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: auth.error != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 300),
                                      builder: (_, v, child) => Opacity(
                                          opacity: v, child: child),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.dangerLight,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppTheme.danger
                                                  .withOpacity(0.3),
                                              width: 0.5),
                                        ),
                                        child: Row(children: [
                                          const Icon(
                                              Icons.error_outline_rounded,
                                              size: 18,
                                              color: AppTheme.danger),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(auth.error!,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.danger,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),

                          // ── Sign in button (scale in) ────────────────────────
                          FadeTransition(
                            opacity: _btnFade,
                            child: ScaleTransition(
                              scale: _btnScale,
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedRole == 0
                                        ? AppTheme.primary
                                        : AppTheme.accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            key: ValueKey('loader'),
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : Row(
                                            key: ValueKey('btn_$_selectedRole'),
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _selectedRole == 0
                                                    ? 'Sign in as Admin'
                                                    : 'Sign in as Supervisor',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            FadeTransition(
              opacity: _btnFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _selectedRole == 0
                      ? 'Contact system administrator for credentials'
                      : 'Contact your admin for login credentials',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppTheme.surfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppTheme.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _selectedRole == 0 ? AppTheme.primary : AppTheme.accent,
          width: 1.5,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Role Pill ─────────────────────────────────────────────────────────────────
class _RolePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RolePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : Colors.white60),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.white60,
                ),
              ),
            ]),
          ),
        ),
      );
}


// ── Input Label ───────────────────────────────────────────────────────────────
class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );
}