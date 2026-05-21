import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// Sree Ram Dyes & Chemicals — Rainbow Color System
// Dark Mode + Light Mode with multi-color vibrancy
// ═══════════════════════════════════════════════════════════════

class AppColors {
  // ── 8 Core Colors (from the logo rainbow wheel) ─────────────
  static const Color red = Color(0xFFE53935);
  static const Color orange = Color(0xFFFB8C00);
  static const Color yellow = Color(0xFFFDD835);
  static const Color green = Color(0xFF43A047);
  static const Color teal = Color(0xFF00897B);
  static const Color blue = Color(0xFF1E88E5);
  static const Color indigo = Color(0xFF3949AB);
  static const Color violet = Color(0xFF8E24AA);

  // ── DARK MODE ────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF111118);
  static const Color surface2 = Color(0xFF16161F);

  // ── LIGHT MODE ───────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF4F5FB);
  static const Color surfaceL = Color(0xFFFFFFFF);
  static const Color surface2L = Color(0xFFEEF0FA);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient rainbow = LinearGradient(
    colors: [red, orange, yellow, green, blue, indigo, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradWarm = LinearGradient(
    colors: [red, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradStock = LinearGradient(
    colors: [green, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradCool = LinearGradient(
    colors: [blue, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradMid = LinearGradient(
    colors: [green, teal, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradAdmin = LinearGradient(
    colors: [red, orange, Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const SweepGradient logoSweep = SweepGradient(
    colors: [red, orange, yellow, green, teal, blue, indigo, violet, red],
  );

  // ── Per-module accent ─────────────────────────────────────────
  static Color forModule(String module) {
    switch (module) {
      case 'products':
        return red;
      case 'stock':
        return green;
      case 'list':
        return orange;
      case 'contacts':
        return violet;
      case 'branches':
        return teal;
      case 'vendors':
        return indigo;
      case 'users':
        return blue;
      case 'history':
        return indigo;
      default:
        return orange;
    }
  }

  static Color labelForModule(String module) {
    switch (module) {
      case 'products':
        return const Color(0xFFEF9A9A);
      case 'stock':
        return const Color(0xFFA5D6A7);
      case 'list':
        return const Color(0xFFFFCC80);
      case 'contacts':
        return const Color(0xFFCE93D8);
      case 'branches':
        return const Color(0xFF80CBC4);
      case 'vendors':
        return const Color(0xFF9FA8DA);
      case 'users':
        return const Color(0xFF90CAF9);
      case 'history':
        return const Color(0xFF9FA8DA);
      default:
        return const Color(0xFFFFCC80);
    }
  }

  // ── Light mode deep label colors ─────────────────────────────
  static Color labelForModuleLight(String module) {
    switch (module) {
      case 'products':
        return const Color(0xFFC62828);
      case 'stock':
        return const Color(0xFF2E7D32);
      case 'list':
        return const Color(0xFFE65100);
      case 'contacts':
        return const Color(0xFF6A1B9A);
      case 'branches':
        return const Color(0xFF00695C);
      case 'vendors':
        return const Color(0xFF283593);
      case 'users':
        return const Color(0xFF1565C0);
      case 'history':
        return const Color(0xFF283593);
      default:
        return const Color(0xFFE65100);
    }
  }

  // ── Theme-aware helpers ───────────────────────────────────────
  static Color bg(bool isDark) => isDark ? bgDark : bgLight;
  static Color card(bool isDark) => isDark ? surface : surfaceL;
  static Color cardElevated(bool isDark) => isDark ? surface2 : surface2L;
  static Color textPrimary(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF1A1A2E);
  static Color textSecondary(bool isDark) =>
      isDark ? Colors.white60 : const Color(0xFF555577);
  static Color textMuted(bool isDark) =>
      isDark ? Colors.white24 : const Color(0xFF9999BB);
  static Color border(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08);
  static Color appBarBg(bool isDark) =>
      isDark ? const Color(0xFF0A0A12) : Colors.white;
  static Color divider(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);
  static Color appBarDivider(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.08);
}
