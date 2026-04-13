import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../theme_provider.dart';
import '../widgets/theme_toggle.dart';
import '../services/api_service.dart';
import 'stock_page.dart';
import 'login_page.dart';

class UserDashboard extends StatelessWidget {
  final String username;
  const UserDashboard({super.key, required this.username});

  Future<void> _logout(BuildContext context, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(isDark))),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.poppins(color: AppColors.textSecondary(isDark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textMuted(isDark))),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradStock,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Logout',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: AppColors.appBarBg(isDark),
          child: SafeArea(
            child: Column(
              children: [
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
                              Text('Staff Dashboard',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textPrimary(isDark),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              Text('Welcome, $username',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary(isDark),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        const ThemeToggleButton(),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _logout(context, isDark),
                          icon: Icon(Icons.logout,
                              color: AppColors.textSecondary(isDark), size: 22),
                          tooltip: 'Logout',
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.gradStock,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text('Staff Account',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('STAFF',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradStock,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Your Module',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(isDark))),
              ],
            ),
            const SizedBox(height: 12),

            // Stock tile
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StockPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.green.withOpacity(isDark ? 0.25 : 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(isDark ? 0.12 : 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.green.withOpacity(isDark ? 0.25 : 0.3)),
                      ),
                      child: const Icon(Icons.warehouse, color: AppColors.green, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Stock Management',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.green
                                          : AppColors.labelForModuleLight('stock'))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradStock,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('FULL ACCESS',
                                    style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add purchases, sales, transfers\nView stock levels & low stock alerts',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary(isDark),
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: AppColors.green, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
