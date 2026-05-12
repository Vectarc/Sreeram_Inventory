import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'theme_provider.dart';
import 'services/api_service.dart';
import 'screens/home_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await ApiService.loadToken();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sree Ram Company',
      themeMode: themeProvider.themeMode,

      // ── DARK THEME ───────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        primaryColor: AppColors.orange,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.orange,
          secondary: AppColors.yellow,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        useMaterial3: false,
      ),

      // ── LIGHT THEME ──────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        primaryColor: AppColors.orange,
        colorScheme: ColorScheme.light(
          primary: AppColors.orange,
          secondary: AppColors.blue,
          surface: AppColors.surfaceL,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF1A1A2E),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        useMaterial3: false,
      ),

      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _loaderController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _checkLogin();
  }

  @override
  void dispose() {
    _loaderController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 2300));
    if (!mounted) return;
    final token = ApiService.token;
    if (token != null) {
      final role = await ApiService.getSavedRole();
      final username = await ApiService.getSavedUsername() ?? '';
      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard(username: username)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserDashboard(username: username)),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Stack(
        children: [
          // Ambient glow — red top-left
          Positioned(
            top: -150, left: -150,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.red.withOpacity(isDark ? 0.13 : 0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          // Ambient glow — violet bottom-right
          Positioned(
            bottom: -150, right: -150,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.violet.withOpacity(isDark ? 0.13 : 0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          // Blue glow top-right (light mode extra)
          if (!isDark) Positioned(
            top: -100, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.blue.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeController,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rainbow ring with logo
                  Container(
                    width: 110, height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.logoSweep,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white : Colors.white,
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  ShaderMask(
                    shaderCallback: (b) => AppColors.rainbow.createShader(b),
                    child: Text(
                      'Sree Ram Company',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradWarm,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Quality  •  Trust  •  Service',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Animated loader bar
                  Container(
                    width: 160, height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: AnimatedBuilder(
                      animation: _loaderController,
                      builder: (ctx, _) {
                        final t = _loaderController.value;
                        final left = t < 0.5 ? 0.0 : (t - 0.5) * 2.0;
                        final width = t < 0.5 ? t * 2 * 0.7 : 0.7;
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: width.clamp(0.0, 1.0),
                          child: FractionalTranslation(
                            translation: Offset(
                              left.clamp(0.0, 1.0) / width.clamp(0.01, 1.0), 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.rainbow,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
