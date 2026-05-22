import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';
import 'admin_dashboard.dart';
import '../widgets/theme_toggle.dart';
import 'login_page.dart';

class AdminBranchSelectionPage extends StatefulWidget {
  final String username;
  final bool isSwitching;

  const AdminBranchSelectionPage({
    super.key,
    required this.username,
    this.isSwitching = false,
  });

  @override
  State<AdminBranchSelectionPage> createState() => _AdminBranchSelectionPageState();
}

class _AdminBranchSelectionPageState extends State<AdminBranchSelectionPage> {
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.getBranches();

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _branches = List<Map<String, dynamic>>.from(result['branches'] ?? []);
      } else {
        _error = result['message'] ?? 'Failed to load branches';
      }
    });
  }

  LinearGradient _getBranchGradient(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sree ram dyes')) {
      return AppColors.gradWarm;
    } else if (lower.contains('sree ramraj')) {
      return AppColors.gradCool;
    } else if (lower.contains('sun shine')) {
      return AppColors.gradAdmin;
    }
    return AppColors.gradMid;
  }

  IconData _getBranchIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sree ram dyes')) {
      return Icons.science_outlined;
    } else if (lower.contains('sree ramraj')) {
      return Icons.gradient;
    } else if (lower.contains('sun shine')) {
      return Icons.wb_sunny_outlined;
    }
    return Icons.storefront_outlined;
  }

  Future<void> _selectBranch(String branchName) async {
    // Save selection to SharedPreferences under the key 'branch'
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('branch', branchName);

    if (!mounted) return;

    if (widget.isSwitching) {
      // Just pop and return the selected branch name
      Navigator.pop(context, branchName);
    } else {
      // Direct replacement flow to AdminDashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(
            username: widget.username,
            selectedBranch: branchName,
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final isDark = context.read<ThemeProvider>().isDark;
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
      if (mounted) {
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

    return PopScope(
      canPop: widget.isSwitching,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0A12) : AppColors.bgLight,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
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
                        children: [
                          if (widget.isSwitching)
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: AppColors.textPrimary(isDark),
                              ),
                              onPressed: () => Navigator.pop(context),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                Icons.logout,
                                color: AppColors.red,
                              ),
                              tooltip: 'Logout',
                              onPressed: _logout,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isSwitching ? 'Switch Branch' : 'Select Branch',
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary(isDark),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const ThemeToggleButton(),
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
                      AppColors.orange.withOpacity(isDark ? 0.08 : 0.05),
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
                      AppColors.violet.withOpacity(isDark ? 0.08 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.orange,
                      strokeWidth: 3,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.red,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _loadBranches,
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                label: Text(
                                  'Retry',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _branches.isEmpty
                        ? Center(
                            child: Text(
                              'No branches found.',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.rainbow.createShader(bounds),
                                  child: Text(
                                    'SRDC',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.isSwitching
                                      ? 'Choose a branch to switch active dashboard context:'
                                      : 'Select a branch to initialize your dashboard session:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ..._branches.map((b) {
                                  final name = b['name'] ?? 'Unknown Branch';
                                  final location = b['location'] ?? 'No location provided';
                                  final gradient = _getBranchGradient(name);
                                  final icon = _getBranchIcon(name);

                                  return BranchCard(
                                    name: name,
                                    location: location,
                                    gradient: gradient,
                                    icon: icon,
                                    onTap: () => _selectBranch(name),
                                  );
                                }),
                              ],
                            ),
                          ),
          ],
        ),
      ),
    );
  }
}

class BranchCard extends StatefulWidget {
  final String name;
  final String location;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final IconData icon;

  const BranchCard({
    super.key,
    required this.name,
    required this.location,
    required this.onTap,
    required this.gradient,
    required this.icon,
  });

  @override
  State<BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<BranchCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.card(isDark),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? widget.gradient.colors.first.withOpacity(0.5)
                    : AppColors.border(isDark),
                width: _isHovered ? 2.0 : 1.5,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: widget.gradient.colors.first.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                else if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors.first.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary(isDark),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: AppColors.textMuted(isDark),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.location,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary(isDark),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted(isDark),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
