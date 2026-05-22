import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../theme_provider.dart';
import '../widgets/theme_toggle.dart';
import '../services/api_service.dart';
import 'product_page.dart';
import 'stock_page.dart';
import 'product_list_page.dart';
import 'contact_page.dart';
import 'branch_management_page.dart';
import 'vendor_management_page.dart';
import 'user_management_page.dart';
import 'login_page.dart';
import 'admin_branch_selection_page.dart';
import 'login_history_page.dart';
import 'dart:async';
import '../widgets/app_notifications.dart';

class AdminDashboard extends StatefulWidget {
  final String username;
  final String selectedBranch;
  const AdminDashboard({
    super.key,
    required this.username,
    required this.selectedBranch,
  });
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _stockAlerts = [];
  bool _alertsLoaded = false;
  late String _selectedBranch;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.selectedBranch;
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final res = await ApiService.getStockAlerts();
    if (mounted && res['success'] == true) {
      final allAlerts = List<Map<String, dynamic>>.from(res['alerts'] ?? []);
      setState(() {
        _stockAlerts = allAlerts.where((alert) {
          final alertBranch = alert['branch']?.toString() ?? '';
          return alertBranch.toLowerCase() == _selectedBranch.toLowerCase();
        }).toList();
        _alertsLoaded = true;
      });
    }
  }

  Future<void> _updateSelectedBranch(String newBranch) async {
    await ApiService.saveUserInfo(widget.username, 'admin', branch: newBranch);
    if (mounted) {
      setState(() {
        _selectedBranch = newBranch;
      });
      _loadAlerts();
    }
  }

  Future<void> _logout(BuildContext context, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary(isDark),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textMuted(isDark)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.clearToken();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _changeAdminPassword(BuildContext context, bool isDark) async {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool saving = false;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.cardElevated(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.gradWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Change Admin Password',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary(isDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Password
              TextField(
                controller: currentPassCtrl,
                obscureText: !showCurrent,
                style: TextStyle(color: AppColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(
                    color: AppColors.blue.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.blue,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrent ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary(isDark),
                      size: 18,
                    ),
                    onPressed: () => ss(() => showCurrent = !showCurrent),
                  ),
                  filled: true,
                  fillColor: AppColors.card(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.blue, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // New Password
              TextField(
                controller: newPassCtrl,
                obscureText: !showNew,
                style: TextStyle(color: AppColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(
                    color: AppColors.green.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_open_outlined,
                    color: AppColors.green,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNew ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary(isDark),
                      size: 18,
                    ),
                    onPressed: () => ss(() => showNew = !showNew),
                  ),
                  filled: true,
                  fillColor: AppColors.card(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.green, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Confirm New Password
              TextField(
                controller: confirmPassCtrl,
                obscureText: !showConfirm,
                style: TextStyle(color: AppColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(
                    color: AppColors.orange.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_clock_outlined,
                    color: AppColors.orange,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirm ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary(isDark),
                      size: 18,
                    ),
                    onPressed: () => ss(() => showConfirm = !showConfirm),
                  ),
                  filled: true,
                  fillColor: AppColors.card(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.orange, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showForgotPasswordFlow(context, isDark);
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        if (currentPassCtrl.text.isEmpty) {
                          AppNotifications.showWarning(
                            context,
                            'Please enter current password',
                          );
                          return;
                        }
                        if (newPassCtrl.text.length < 6) {
                          AppNotifications.showWarning(
                            context,
                            'New password must be at least 6 characters',
                          );
                          return;
                        }
                        if (newPassCtrl.text != confirmPassCtrl.text) {
                          AppNotifications.showError(
                            context,
                            'New password and confirm password do not match',
                          );
                          return;
                        }
                        ss(() => saving = true);
                        final res = await ApiService.changeAdminPassword(
                          currentPassCtrl.text,
                          newPassCtrl.text,
                        );
                        ss(() => saving = false);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          AppNotifications.showSuccess(
                            context,
                            'Admin password updated!',
                          );
                        } else {
                          AppNotifications.showError(
                            context,
                            res['message'] ?? 'Failed to update password',
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Forgot Password OTP Flow ──────────────────────────────────────
  Future<void> _showForgotPasswordFlow(
    BuildContext context,
    bool isDark,
  ) async {
    // Step 1: Request OTP – sent to main branch email
    bool sendingOtp = false;
    String? otpError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.cardElevated(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.mail_outline,
                  color: AppColors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Forgot Password',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(isDark ? 0.1 : 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.blue, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'A one-time password (OTP) will be sent to the main branch email address registered with this admin account.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary(isDark),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (otpError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Text(
                    otpError!,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: sendingOtp
                    ? null
                    : () async {
                        ss(() {
                          sendingOtp = true;
                          otpError = null;
                        });
                        final res =
                            await ApiService.sendAdminForgotPasswordOtp();
                        ss(() => sendingOtp = false);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          if (context.mounted) {
                            _showOtpVerificationDialog(context, isDark);
                          }
                        } else {
                          ss(
                            () => otpError =
                                res['message'] ??
                                'Failed to send OTP. Please try again.',
                          );
                        }
                      },
                child: sendingOtp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Send OTP',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOtpVerificationDialog(
    BuildContext context,
    bool isDark,
  ) async {
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool verifying = false;
    bool showNew = false;
    bool showConfirm = false;
    String? errorMsg;
    int secondsLeft = 120; // 2 minute timer
    Timer? countdownTimer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          // Start timer on first build
          countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (!ctx.mounted) {
              t.cancel();
              return;
            }
            ss(() {
              if (secondsLeft > 0) {
                secondsLeft--;
              } else {
                t.cancel();
              }
            });
          });

          final mins = (secondsLeft ~/ 60).toString().padLeft(2, '0');
          final secs = (secondsLeft % 60).toString().padLeft(2, '0');
          final timerExpired = secondsLeft == 0;

          return AlertDialog(
            backgroundColor: AppColors.cardElevated(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (timerExpired ? Colors.red : AppColors.green)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (timerExpired ? Colors.red : AppColors.green)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: timerExpired ? Colors.red : AppColors.green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Enter OTP',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary(isDark),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: timerExpired
                          ? Colors.red.withOpacity(isDark ? 0.1 : 0.06)
                          : AppColors.green.withOpacity(isDark ? 0.1 : 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: timerExpired
                            ? Colors.red.withOpacity(0.25)
                            : AppColors.green.withOpacity(0.25),
                      ),
                    ),
                    child: timerExpired
                        ? Column(
                            children: [
                              Icon(
                                Icons.timer_off,
                                color: Colors.red,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'OTP Expired!',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Please request a new OTP',
                                style: GoogleFonts.poppins(
                                  color: Colors.red.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: AppColors.green,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'OTP expires in',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary(isDark),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '$mins:$secs',
                                style: GoogleFonts.poppins(
                                  color: secondsLeft <= 30
                                      ? Colors.orange
                                      : AppColors.green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  if (!timerExpired) ...[
                    // OTP field
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        labelStyle: TextStyle(
                          color: AppColors.green.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.pin_outlined,
                          color: AppColors.green,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.border(isDark),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.green,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // New Password
                    TextField(
                      controller: newPassCtrl,
                      obscureText: !showNew,
                      style: TextStyle(color: AppColors.textPrimary(isDark)),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(
                          color: AppColors.blue.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_open_outlined,
                          color: AppColors.blue,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNew ? Icons.visibility : Icons.visibility_off,
                            color: AppColors.textSecondary(isDark),
                            size: 18,
                          ),
                          onPressed: () => ss(() => showNew = !showNew),
                        ),
                        filled: true,
                        fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.border(isDark),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.blue,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Confirm Password
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: !showConfirm,
                      style: TextStyle(color: AppColors.textPrimary(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(
                          color: AppColors.orange.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_clock_outlined,
                          color: AppColors.orange,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary(isDark),
                            size: 18,
                          ),
                          onPressed: () => ss(() => showConfirm = !showConfirm),
                        ),
                        filled: true,
                        fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.border(isDark),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.orange,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              errorMsg!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
              ),
              if (timerExpired)
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradWarm,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      countdownTimer?.cancel();
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        _showForgotPasswordFlow(context, isDark);
                      }
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      'Generate New OTP',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: verifying
                        ? null
                        : () async {
                            if (otpCtrl.text.trim().length < 4) {
                              ss(
                                () => errorMsg =
                                    'Please enter the OTP sent to your email',
                              );
                              return;
                            }
                            if (newPassCtrl.text.length < 6) {
                              ss(
                                () => errorMsg =
                                    'New password must be at least 6 characters',
                              );
                              return;
                            }
                            if (newPassCtrl.text != confirmPassCtrl.text) {
                              ss(() => errorMsg = 'Passwords do not match');
                              return;
                            }
                            ss(() {
                              verifying = true;
                              errorMsg = null;
                            });
                            final res =
                                await ApiService.resetAdminPasswordWithOtp(
                                  otpCtrl.text.trim(),
                                  newPassCtrl.text,
                                );
                            ss(() => verifying = false);
                            if (res['success'] == true) {
                              countdownTimer?.cancel();
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                AppNotifications.showSuccess(
                                  context,
                                  'Password reset successfully! Please log in again.',
                                );
                                await ApiService.clearToken();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            } else {
                              ss(
                                () => errorMsg =
                                    res['message'] ??
                                    'Invalid OTP. Please try again.',
                              );
                            }
                          },
                    child: verifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Reset Password',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    countdownTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(122),
        child: Container(
          color: AppColors.appBarBg(isDark),
          child: SafeArea(
            child: Column(
              children: [
                // Rainbow bar at top
                Container(
                  height: 3,
                  decoration: const BoxDecoration(gradient: AppColors.rainbow),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textPrimary(isDark),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Welcome, ${widget.username}',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary(isDark),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Theme toggle button
                        const ThemeToggleButton(),
                        const SizedBox(width: 8),
                        // Logout button
                        GestureDetector(
                          onTap: () => _logout(context, isDark),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE53935,
                              ).withOpacity(isDark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFE53935,
                                ).withOpacity(0.28),
                              ),
                            ),
                            child: Icon(
                              Icons.logout,
                              color: isDark
                                  ? const Color(0xFFEF9A9A)
                                  : const Color(0xFFC62828),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Branch selection info bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          color: AppColors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedBranch,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary(isDark),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final newBranch = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminBranchSelectionPage(
                                  username: widget.username,
                                  isSwitching: true,
                                ),
                              ),
                            );
                            if (newBranch != null && newBranch.isNotEmpty) {
                              await _updateSelectedBranch(newBranch);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradWarm,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Switch',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: AppColors.appBarDivider(isDark)),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Admin badge ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0x26E53935), const Color(0x268E24AA)]
                        : [const Color(0x18E53935), const Color(0x188E24AA)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(isDark)),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.red.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.rainbow,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.rainbow.createShader(b),
                          child: Text(
                            'Administrator',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          'Full access to all modules',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.vpn_key_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      tooltip: 'Change Admin Password',
                      onPressed: () => _changeAdminPassword(context, isDark),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stock Alert Banner ────────────────────────────────
            if (_alertsLoaded && _stockAlerts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Low Stock Alerts',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange.shade800,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${_stockAlerts.length} item(s) below minimum level',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...(_stockAlerts.take(3).map((alert) {
                        final product = alert['product'];
                        final name = product is Map
                            ? (product['name'] ?? '')
                            : (alert['productName'] ?? '');
                        final qty = alert['quantity'] ?? 0;
                        final minLevel = alert['minLevel'] ?? 0;
                        return Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary(isDark),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (alert['branch'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Text(
                                          alert['branch'].toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (alert['reasons'] != null &&
                                        (alert['reasons'] as List).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Wrap(
                                          spacing: 4,
                                          children: (alert['reasons'] as List)
                                              .map(
                                                (reason) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 1,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (reason == 'Low Stock'
                                                                ? Colors.orange
                                                                : Colors.red)
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          (reason == 'Low Stock'
                                                                  ? Colors
                                                                        .orange
                                                                  : Colors.red)
                                                              .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    reason.toString(),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          reason == 'Low Stock'
                                                          ? Colors
                                                                .orange
                                                                .shade800
                                                          : Colors.red.shade800,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  '$qty / $minLevel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })),
                      if (_stockAlerts.length > 3)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Text(
                            '+${_stockAlerts.length - 3} more — check Stock Management',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],

            // ── MODULES label ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
              child: Text(
                'MODULES',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted(isDark),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.inventory_2_outlined,
                          label: 'Products',
                          sub: 'Add, Edit products',
                          module: 'products',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductPage(branch: _selectedBranch),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.warehouse_outlined,
                          label: 'Stock\nManagement',
                          sub: 'Track inventory',
                          module: 'stock',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StockPage(branch: _selectedBranch),
                              ),
                            );
                            _loadAlerts();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.list_alt_outlined,
                          label: 'Product\nList',
                          sub: 'View all products',
                          module: 'list',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductListPage(branch: _selectedBranch),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.contacts_outlined,
                          label: 'Contacts',
                          sub: 'Manage contacts',
                          module: 'contacts',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContactPage(branch: _selectedBranch),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.store_outlined,
                          label: 'Branch\nManagement',
                          sub: 'Add, Edit branches',
                          module: 'branches',
                          onTap: () async {
                            final updatedBranch = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BranchManagementPage(
                                  selectedBranchName: _selectedBranch,
                                ),
                              ),
                            );
                            if (updatedBranch != null &&
                                updatedBranch != _selectedBranch) {
                              setState(() {
                                _selectedBranch = updatedBranch;
                              });
                              _loadAlerts();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.business_outlined,
                          label: 'Vendor\nManagement',
                          sub: 'Add, Edit vendors',
                          module: 'vendors',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VendorManagementPage(branch: _selectedBranch),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.manage_accounts_outlined,
                          label: 'User\nManagement',
                          sub: 'Create & delete users',
                          module: 'users',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserManagementPage(
                                selectedBranchName: _selectedBranch,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tile(
                          context,
                          isDark,
                          icon: Icons.history_toggle_off_rounded,
                          label: 'Login\nHistory',
                          sub: 'Last 20 user logins',
                          module: 'history',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginHistoryPage(
                                selectedBranchName: _selectedBranch,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Footer rainbow bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: AppColors.rainbow,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '© 2026 Sree Ram Dyes & Chemicals',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textMuted(isDark),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String sub,
    required String module,
    required VoidCallback onTap,
  }) {
    final accentColor = AppColors.forModule(module);
    final labelColor = isDark
        ? AppColors.labelForModule(module)
        : AppColors.labelForModuleLight(module);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(isDark)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: accentColor.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              bottom: -10,
              right: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(isDark ? 0.09 : 0.12),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withOpacity(isDark ? 0.32 : 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.textSecondary(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileFullWidth(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String sub,
    required String module,
    required VoidCallback onTap,
  }) {
    final accentColor = AppColors.forModule(module);
    final labelColor = isDark
        ? AppColors.labelForModule(module)
        : AppColors.labelForModuleLight(module);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(isDark)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: accentColor.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(isDark ? 0.32 : 0.4),
                ),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
