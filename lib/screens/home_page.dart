import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../theme_provider.dart';
import '../widgets/theme_toggle.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'public_products_page.dart';
import 'public_contacts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  int _productCount = 0;
  int _contactCount = 0;

  // Feature Flags
  final bool _showProducts = false;
  final bool _showContacts = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getPublicBranches(),
      ApiService.getProducts(),
      ApiService.getContacts(),
    ]);
    if (mounted) {
      setState(() {
        if (results[0]['success'] == true) {
          _branches = List<Map<String, dynamic>>.from(
            results[0]['branches'] ?? [],
          );
        }
        if (results[1]['success'] == true) {
          final products = List<Map<String, dynamic>>.from(
            results[1]['products'] ?? [],
          );
          _productCount = products.where((p) => p['isActive'] == true).length;
        }
        if (results[2]['success'] == true) {
          _contactCount = (results[2]['contacts'] as List?)?.length ?? 0;
        }
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? get _mainBranch {
    try {
      return _branches.firstWhere((b) => b['isMain'] == true);
    } catch (_) {
      return _branches.isNotEmpty ? _branches.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final main = _mainBranch;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.bgLight,
      drawer: _buildDrawer(context, isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Builder(
                          builder: (ctx) => GestureDetector(
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.07)
                                    : Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                Icons.menu,
                                color: AppColors.textPrimary(isDark),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            gradient: const SweepGradient(
                              colors: [
                                AppColors.red,
                                AppColors.orange,
                                AppColors.yellow,
                                AppColors.green,
                                AppColors.blue,
                                AppColors.violet,
                                AppColors.red,
                              ],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: isDark
                                  ? const Color(0xFF0A0A12)
                                  : Colors.white,
                              image: const DecorationImage(
                                image: AssetImage('assets/logo.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SRDC',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary(isDark),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HERO CARD
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF0D0D1A),
                                    const Color(0xFF1A0A20),
                                  ]
                                : [
                                    const Color(0xFFFFF8F0),
                                    const Color(0xFFF0F4FF),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border(isDark)),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppColors.orange.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      AppColors.red,
                                      AppColors.orange,
                                      AppColors.yellow,
                                      AppColors.green,
                                      AppColors.blue,
                                      AppColors.violet,
                                      AppColors.red,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? const Color(
                                          0xFF0D0D1A,
                                        ).withOpacity(0.78)
                                      : const Color(
                                          0xFFFFF8F0,
                                        ).withOpacity(0.78),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        AppColors.red,
                                        AppColors.orange,
                                        AppColors.yellow,
                                        AppColors.green,
                                        AppColors.blue,
                                        AppColors.violet,
                                        AppColors.red,
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF0A0A12)
                                          : Colors.white,
                                      image: const DecorationImage(
                                        image: AssetImage('assets/logo.png'),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      WidgetSpan(
                                        child: ShaderMask(
                                          shaderCallback: (b) =>
                                              const LinearGradient(
                                                colors: [
                                                  Color(0xFFE53935),
                                                  Color(0xFFFB8C00),
                                                ],
                                              ).createShader(b),
                                          child: Text(
                                            'SRDC',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Est. 1992 · Tirupur, Tamil Nadu',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.07)
                                        : AppColors.orange.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.12)
                                          : AppColors.orange.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    'QUALITY · TRUST · SERVICE',
                                    style: GoogleFonts.poppins(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.7)
                                          : AppColors.orange,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showProducts || _showContacts) ...[
                      _sectionLabel('QUICK ACCESS', isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            if (_showProducts)
                              Expanded(
                                child: _quickCard(
                                  context,
                                  isDark,
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Products',
                                  badge: _productCount > 0
                                      ? '$_productCount'
                                      : null,
                                  accentColor: AppColors.red,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PublicProductsPage(),
                                    ),
                                  ),
                                ),
                              ),
                            if (_showProducts && _showContacts)
                              const SizedBox(width: 8),
                            if (_showContacts)
                              Expanded(
                                child: _quickCard(
                                  context,
                                  isDark,
                                  icon: Icons.contacts_outlined,
                                  label: 'Contacts',
                                  badge: _contactCount > 0
                                      ? '$_contactCount'
                                      : null,
                                  accentColor: AppColors.violet,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PublicContactsPage(),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    _sectionLabel('ABOUT', isDark),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(isDark)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ABOUT US',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sree Ram Dyes & Chemicals is a textile screen printing inks company established in Tirupur, Tamil Nadu, India, around the early 1992 by Mr. C. Sharavanan. It began with trading textile-grade screen printing inks, dyes and chemicals and expanded by importing a variety of inks from overseas to serve diverse customer needs.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary(isDark),
                                height: 1.65,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_branches.isNotEmpty) ...[
                      _sectionLabel('BRANCHES', isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: _branches
                              .map(
                                (b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _branchCard(
                                    isDark: isDark,
                                    emoji: b['isMain'] == true ? '🏬' : '🏪',
                                    name: b['name'] ?? '',
                                    address: b['location'] ?? '',
                                    isMain: b['isMain'] == true,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    if (main != null) ...[
                      _sectionLabel('CONTACT', isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            if ((main['phone'] ?? '').isNotEmpty)
                              _infoRow(
                                isDark,
                                Icons.phone,
                                AppColors.green,
                                'Phone',
                                main['phone'],
                              ),
                            if ((main['email'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _infoRow(
                                isDark,
                                Icons.email_outlined,
                                AppColors.blue,
                                'Email',
                                main['email'],
                              ),
                            ],
                            if ((main['officeHours'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _infoRow(
                                isDark,
                                Icons.access_time,
                                AppColors.violet,
                                'Business Hours',
                                main['officeHours'],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.appBarBg(isDark),
                        border: Border(
                          top: BorderSide(
                            color: AppColors.appBarDivider(isDark),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: AppColors.rainbow,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '© 2026 SRDC. All Rights Reserved.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: AppColors.textMuted(isDark),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  static Widget _sectionLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: AppColors.textMuted(isDark),
      ),
    ),
  );

  static Widget _quickCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    String? badge,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardElevated(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : accentColor.withOpacity(0.15),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: accentColor.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: accentColor, size: 21),
                ),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white.withOpacity(0.85) : accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _branchCard({
    required bool isDark,
    required String emoji,
    required String name,
    required String address,
    required bool isMain,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isMain
              ? AppColors.orange.withOpacity(isDark ? 0.3 : 0.4)
              : AppColors.border(isDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isMain
                        ? AppColors.orange
                        : AppColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecondary(isDark),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(
    bool isDark,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textPrimary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: AppColors.card(isDark),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(gradient: AppColors.gradWarm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.red,
                        AppColors.orange,
                        AppColors.yellow,
                        AppColors.green,
                        AppColors.blue,
                        AppColors.violet,
                        AppColors.red,
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SRDC',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Text(
                    'Quality  •  Trust  •  Service',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 3,
            decoration: const BoxDecoration(gradient: AppColors.rainbow),
          ),
          const SizedBox(height: 8),
          if (_showProducts)
            _drawerItem(
              context,
              isDark,
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              sub: 'View all active products',
              color: AppColors.red,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PublicProductsPage()),
                );
              },
            ),
          if (_showContacts)
            _drawerItem(
              context,
              isDark,
              icon: Icons.contacts_outlined,
              label: 'Contacts',
              sub: 'Transport, Staff, Services',
              color: AppColors.violet,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PublicContactsPage()),
                );
              },
            ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.divider(isDark),
          ),
          const SizedBox(height: 8),
          _drawerItem(
            context,
            isDark,
            icon: Icons.login,
            label: 'Login',
            sub: 'Admin / Staff login',
            color: AppColors.orange,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© 2024 SRDC',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _drawerItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      subtitle: Text(
        sub,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: AppColors.textSecondary(isDark),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: color.withOpacity(0.6),
        size: 12,
      ),
    );
  }
}
