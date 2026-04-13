import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../theme_provider.dart';
import '../widgets/theme_toggle.dart';
import '../services/api_service.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'home_page.dart';
import 'dart:async';
import '../widgets/app_notifications.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _adminUser = TextEditingController();
  final _adminPass = TextEditingController();
  bool _adminPassVis = false;
  final _userUser = TextEditingController();
  final _userPass = TextEditingController();
  bool _userPassVis = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _adminUser.dispose();
    _adminPass.dispose();
    _userUser.dispose();
    _userPass.dispose();
    super.dispose();
  }

  Future<void> _adminLogin() async {
    final u = _adminUser.text.trim();
    final p = _adminPass.text.trim();
    if (u.isEmpty || p.isEmpty) {
      _snack('Please enter username and password');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.adminLogin(u, p);
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      await ApiService.setToken(result['token']);
      await ApiService.saveUserInfo(result['user']['username'], 'admin');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(username: result['user']['username']),
        ),
      );
    } else {
      _showErrorAlert(
        result['message'] ?? 'Login failed. Please check your credentials.',
      );
    }
  }

  Future<void> _userLogin() async {
    final u = _userUser.text.trim();
    final p = _userPass.text.trim();
    if (u.isEmpty || p.isEmpty) {
      _snack('Please enter username and password');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.userLogin(u, p);
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      await ApiService.setToken(result['token']);
      await ApiService.saveUserInfo(result['user']['username'], 'user');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserDashboard(username: result['user']['username']),
        ),
      );
    } else {
      _showErrorAlert(
        result['message'] ?? 'Login failed. Please check your credentials.',
      );
    }
  }

  void _snack(String msg) {
    AppNotifications.showInfo(context, msg);
  }

  void _showErrorAlert(String message) {
    final isDark = context.read<ThemeProvider>().isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.red, size: 28),
            const SizedBox(width: 10),
            Text(
              'Login Failed',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg(isDark),
        body: Stack(
          children: [
            // Ambient glows
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.red.withOpacity(isDark ? 0.1 : 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(isDark ? 0.1 : 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.card(isDark),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.border(isDark),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.textPrimary(isDark),
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary(isDark),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const ThemeToggleButton(),
                      ],
                    ),
                  ),

                  // Logo
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.logoSweep,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.bgDark : Colors.white,
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.rainbow.createShader(b),
                    child: const Text(
                      'Sree Ram Company',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please sign in to continue',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary(isDark),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card(isDark),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                const BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 20,
                                  offset: Offset(0, -4),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 3,
                            decoration: const BoxDecoration(
                              gradient: AppColors.rainbow,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.cardElevated(isDark),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.border(isDark),
                              ),
                            ),
                            child: TabBar(
                              controller: _tab,
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              unselectedLabelStyle: GoogleFonts.poppins(
                                fontSize: 13,
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary(isDark),
                              indicator: BoxDecoration(
                                gradient: AppColors.gradWarm,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        size: 15,
                                      ),
                                      SizedBox(width: 5),
                                      Text('Admin'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, size: 15),
                                      SizedBox(width: 5),
                                      Text('User / Staff'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: TabBarView(
                              controller: _tab,
                              children: [
                                _loginForm(
                                  isDark,
                                  _adminUser,
                                  _adminPass,
                                  _adminPassVis,
                                  () => setState(
                                    () => _adminPassVis = !_adminPassVis,
                                  ),
                                  _adminLogin,
                                  AppColors.red,
                                  'Admin',
                                ),
                                _loginForm(
                                  isDark,
                                  _userUser,
                                  _userPass,
                                  _userPassVis,
                                  () => setState(
                                    () => _userPassVis = !_userPassVis,
                                  ),
                                  _userLogin,
                                  AppColors.green,
                                  'User',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.card(isDark),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: AppColors.rainbow,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          color: AppColors.orange,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please wait...',
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary(isDark),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAdminForgotPasswordFlow(bool isDark, Color color) async {
    bool sendingOtp = false;
    String? otpError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.cardElevated(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.mail_outline, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(child: Text('Admin Forgot Password',
                style: GoogleFonts.poppins(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: color, size: 16),
                    const SizedBox(width: 8),
                    Flexible(child: Text('An OTP will be sent to the main branch email to reset the admin password.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary(isDark), height: 1.4))),
                  ],
                ),
              ),
              if (otpError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.25))),
                  child: Text(otpError!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(isDark))),
            ),
            Container(
              decoration: BoxDecoration(gradient: AppColors.gradWarm, borderRadius: BorderRadius.circular(8)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: sendingOtp
                    ? null
                    : () async {
                        ss(() { sendingOtp = true; otpError = null; });
                        final res = await ApiService.sendAdminForgotPasswordOtp();
                        ss(() => sendingOtp = false);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          if (mounted) _showLoginOtpVerification(isDark, color);
                        } else {
                          ss(() => otpError = res['message'] ?? 'Failed to send OTP.');
                        }
                      },
                child: sendingOtp
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Send OTP', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLoginOtpVerification(bool isDark, Color color) async {
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool verifying = false;
    bool showNew = false;
    bool showConfirm = false;
    String? errorMsg;
    int secondsLeft = 120;
    Timer? countdownTimer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (!ctx.mounted) { t.cancel(); return; }
            ss(() { if (secondsLeft > 0) {
              secondsLeft--;
            } else {
              t.cancel();
            } });
          });
          final mins = (secondsLeft ~/ 60).toString().padLeft(2, '0');
          final secs = (secondsLeft % 60).toString().padLeft(2, '0');
          final expired = secondsLeft == 0;

          return AlertDialog(
            backgroundColor: AppColors.cardElevated(isDark),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Reset Admin Password',
              style: GoogleFonts.poppins(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 15)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: (expired ? Colors.red : AppColors.green).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (expired ? Colors.red : AppColors.green).withOpacity(0.25)),
                    ),
                    child: expired
                        ? Column(children: [
                            const Icon(Icons.timer_off, color: Colors.red, size: 24),
                            Text('OTP Expired!', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w700)),
                          ])
                        : Column(children: [
                            Text('OTP expires in', style: GoogleFonts.poppins(color: AppColors.textSecondary(isDark), fontSize: 11)),
                            Text('$mins:$secs', style: GoogleFonts.poppins(
                              color: secondsLeft <= 30 ? Colors.orange : AppColors.green,
                              fontWeight: FontWeight.w800, fontSize: 22)),
                          ]),
                  ),
                  if (!expired) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 5),
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        counterText: '',
                        labelStyle: TextStyle(color: color.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.pin_outlined, color: color, size: 18),
                        filled: true, fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border(isDark))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: !showNew,
                      style: TextStyle(color: AppColors.textPrimary(isDark)),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: AppColors.blue.withOpacity(0.7), fontSize: 13),
                        prefixIcon: Icon(Icons.lock_open_outlined, color: AppColors.blue, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(showNew ? Icons.visibility : Icons.visibility_off, color: AppColors.textSecondary(isDark), size: 18),
                          onPressed: () => ss(() => showNew = !showNew),
                        ),
                        filled: true, fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border(isDark))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.blue, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: !showConfirm,
                      style: TextStyle(color: AppColors.textPrimary(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(color: AppColors.orange.withOpacity(0.7), fontSize: 13),
                        prefixIcon: Icon(Icons.lock_clock_outlined, color: AppColors.orange, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(showConfirm ? Icons.visibility : Icons.visibility_off, color: AppColors.textSecondary(isDark), size: 18),
                          onPressed: () => ss(() => showConfirm = !showConfirm),
                        ),
                        filled: true, fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border(isDark))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.orange, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.25))),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 15),
                        const SizedBox(width: 6),
                        Flexible(child: Text(errorMsg!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red))),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () { countdownTimer?.cancel(); Navigator.pop(ctx); },
                child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(isDark))),
              ),
              if (expired)
                Container(
                  decoration: BoxDecoration(gradient: AppColors.gradWarm, borderRadius: BorderRadius.circular(8)),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      countdownTimer?.cancel();
                      Navigator.pop(ctx);
                      if (mounted) _showAdminForgotPasswordFlow(isDark, color);
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                    label: Text('Generate New OTP', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: verifying
                        ? null
                        : () async {
                            if (otpCtrl.text.trim().length < 4) { ss(() => errorMsg = 'Please enter the OTP'); return; }
                            if (newPassCtrl.text.length < 6) { ss(() => errorMsg = 'Password must be at least 6 characters'); return; }
                            if (newPassCtrl.text != confirmPassCtrl.text) { ss(() => errorMsg = 'Passwords do not match'); return; }
                            ss(() { verifying = true; errorMsg = null; });
                            final res = await ApiService.resetAdminPasswordWithOtp(otpCtrl.text.trim(), newPassCtrl.text);
                            ss(() => verifying = false);
                            if (res['success'] == true) {
                              countdownTimer?.cancel();
                              Navigator.pop(ctx);
                                if (mounted) {
                                  AppNotifications.showSuccess(context, 'Password reset! Please log in with your new password.');
                                }
                            } else {
                              ss(() => errorMsg = res['message'] ?? 'Invalid OTP. Please try again.');
                            }
                          },
                    child: verifying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Reset Password', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
            ],
          );
        },
      ),
    );
    countdownTimer?.cancel();
  }

  Widget _loginForm(
    bool isDark,
    TextEditingController userCtrl,
    TextEditingController passCtrl,
    bool passVis,
    VoidCallback togglePass,
    Future<void> Function() onSubmit,
    Color color,
    String role,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          _field(
            isDark: isDark,
            controller: userCtrl,
            label: 'Username',
            icon: Icons.person_outline,
            color: color,
          ),
          const SizedBox(height: 14),
          _passField(
            isDark: isDark,
            controller: passCtrl,
            passVis: passVis,
            onToggle: togglePass,
            color: color,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                if (role == 'User') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.cardElevated(isDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Please contact the admin for your password or to request a password reset.',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'OK',
                            style: GoogleFonts.poppins(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Admin forgot password - show OTP flow
                  _showAdminForgotPasswordFlow(isDark, color);
                }
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Sign In as $role',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(
        color: AppColors.textPrimary(isDark),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: color.withOpacity(0.7),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: AppColors.cardElevated(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(isDark), width: 1),
        ),
      ),
    );
  }

  Widget _passField({
    required bool isDark,
    required TextEditingController controller,
    required bool passVis,
    required VoidCallback onToggle,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      obscureText: !passVis,
      style: GoogleFonts.poppins(
        color: AppColors.textPrimary(isDark),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: GoogleFonts.poppins(
          color: color.withOpacity(0.7),
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: color, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            passVis ? Icons.visibility : Icons.visibility_off,
            color: isDark ? Colors.white38 : AppColors.textSecondary(isDark),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.cardElevated(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(isDark), width: 1),
        ),
      ),
    );
  }
}
