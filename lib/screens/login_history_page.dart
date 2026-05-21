import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import '../services/api_service.dart';

class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({super.key});

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final result = await ApiService.getUserLoginHistory();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _history = List<Map<String, dynamic>>.from(result['history'] ?? []);
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    
    int hour = dt.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    
    final minute = dt.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final accentColor = AppColors.forModule('history');

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.rainbow, // Using rainbow gradient directly or Warm
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'User Login History',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const ThemeToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadHistory,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 56,
                        color: AppColors.textMuted(isDark),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No login history found.',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(isDark),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'User logins will appear here.',
                        style: GoogleFonts.poppins(
                          color: AppColors.textMuted(isDark),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Header Bar
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(isDark ? 0.1 : 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security Monitoring Active',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Showing the last 20 user login activities chronologically.',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _history.length,
                        itemBuilder: (ctx, i) {
                          final h = _history[i];
                          final String username = h['username'] ?? 'Unknown User';
                          final String branch = h['branch'] ?? 'Unknown Branch';
                          final String loginTimeStr = h['login_time'] ?? '';

                          // Format the timestamp nicely
                          String formattedTime = 'N/A';
                          if (loginTimeStr.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(loginTimeStr).toLocal();
                              formattedTime = _formatDateTime(dt);
                            } catch (_) {
                              formattedTime = loginTimeStr;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.card(isDark),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border(isDark)),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  // Leading circular badge/avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.rainbow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                username,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary(isDark),
                                                ),
                                              ),
                                            ),
                                            _badge(
                                              isDark,
                                              branch.toUpperCase(),
                                              AppColors.indigo,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_filled_rounded,
                                              size: 13,
                                              color: AppColors.textMuted(isDark),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              formattedTime,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppColors.textSecondary(isDark),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _badge(bool isDark, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
}
